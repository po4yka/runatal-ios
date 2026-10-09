//
//  QuoteRepository.swift
//  RunicQuotes
//
//  Created by Claude on 30.09.25.
//

import Foundation
import os
import SwiftData

// swiftlint:disable file_length
// swiftlint:disable function_parameter_count

/// Sendable snapshot of a Quote model used across actor boundaries.
struct QuoteRecord: Identifiable {
    let id: UUID
    let textLatin: String
    let author: String
    let source: String?
    let collection: QuoteCollection
    let runicElder: String?
    let runicYounger: String?
    let runicCirth: String?
    let createdAt: Date
    let isHidden: Bool
    let isDeleted: Bool
    let deletedAt: Date?
    let isUserGenerated: Bool

    init(from quote: Quote) {
        self.id = quote.id
        self.textLatin = quote.textLatin
        self.author = quote.author
        self.source = quote.source
        self.collection = quote.collection
        self.runicElder = quote.runicElder
        self.runicYounger = quote.runicYounger
        self.runicCirth = quote.runicCirth
        self.createdAt = quote.createdAt
        self.isHidden = quote.isHidden
        self.isDeleted = quote.isSoftDeleted
        self.deletedAt = quote.deletedAt
        self.isUserGenerated = quote.isUserGenerated
    }

    func runicText(for script: RunicScript) -> String? {
        switch script {
        case .elder:
            self.runicElder
        case .younger:
            self.runicYounger
        case .cirth:
            self.runicCirth
        }
    }
}

/// Protocol defining the quote repository interface
protocol QuoteRepository: Sendable {
    /// Seed the database with initial quotes if needed
    func seedIfNeeded() throws

    /// Get the quote of the day for a specific script
    func quoteOfTheDay(for script: RunicScript) throws -> QuoteRecord

    /// Get a random quote for a specific script
    func randomQuote(for script: RunicScript) throws -> QuoteRecord

    /// Get all quotes
    func allQuotes() throws -> [QuoteRecord]

    /// Get a quote by identifier regardless of archive state.
    func quote(id: UUID) throws -> QuoteRecord?

    /// Get hidden and soft-deleted quotes.
    func archivedQuotes() throws -> [QuoteRecord]

    /// Create a new user-generated quote and return its record.
    func createQuote(
        textLatin: String,
        author: String,
        source: String?,
        collection: QuoteCollection,
        storedRunic: RunicTextBundle?,
        translations: [TranslationResult],
    ) throws -> QuoteRecord

    /// Update an existing quote by ID.
    func updateQuote(
        id: UUID,
        textLatin: String,
        author: String,
        source: String?,
        collection: QuoteCollection,
        storedRunic: RunicTextBundle?,
    ) throws -> QuoteRecord

    /// Hide a quote without deleting it.
    func hideQuote(id: UUID) throws -> QuoteRecord

    /// Soft delete a quote.
    func softDeleteQuote(id: UUID, deletedAt: Date) throws -> QuoteRecord

    /// Restore a hidden or soft-deleted quote.
    func restoreQuote(id: UUID) throws -> QuoteRecord

    /// Permanently erase a quote and any cached translations.
    func eraseQuote(id: UUID) throws

    /// Purge soft-deleted quotes older than the supplied date.
    func purgeDeletedQuotes(before cutoffDate: Date) throws -> Int
}

// swiftlint:disable type_body_length
/// SwiftData implementation of the QuoteRepository
///
/// Safety: each repository instance and its non-Sendable `ModelContext` remain confined
/// to one owning `ModelActor` executor or the UI's main actor. Repository instances
/// must never be shared between those owners; only Sendable DTOs cross the boundary.
final class SwiftDataQuoteRepository: QuoteRepository, @unchecked Sendable {
    typealias Commit = @Sendable (ModelContext) throws -> Void

    private let modelContainer: ModelContainer
    private let commit: Commit
    private let transliterator = RunicTransliterator.self
    private let logger = Logger(subsystem: AppConstants.loggingSubsystem, category: "Repository")

    init(modelContext: ModelContext, commit: @escaping Commit = { try $0.save() }) {
        self.modelContainer = modelContext.container
        self.commit = commit
    }

    private func makeContext() -> ModelContext {
        let context = ModelContext(self.modelContainer)
        context.autosaveEnabled = false
        return context
    }

    private func transaction<T>(_ body: (ModelContext) throws -> T) throws -> T {
        let context = self.makeContext()
        do {
            let result = try body(context)
            try self.commit(context)
            return result
        } catch {
            context.rollback()
            throw error
        }
    }

    // MARK: - Seeding

    func seedIfNeeded() throws {
        try self.transaction { context in
            // Check if database is already seeded
            let descriptor = FetchDescriptor<Quote>()
            let existingQuotes = try context.fetch(descriptor)

            guard existingQuotes.isEmpty else {
                try self.backfillCollectionsIfNeeded(for: existingQuotes, in: context)
                self.migrateLegacyCirthIfNeeded(for: existingQuotes)
                self.logger.info("Database already seeded with \(existingQuotes.count) quotes")
                return
            }

            self.logger.info("Seeding database with quotes...")

            // Load quotes from JSON
            guard let url = seedDataURL() else {
                throw QuoteRepositoryError.seedDataNotFound
            }
            let data = try Data(contentsOf: url)

            let quoteDataArray = try decodeSeedData(from: data)

            // Create Quote objects and transliterate
            for quoteData in quoteDataArray {
                let quote = Quote(
                    textLatin: quoteData.textLatin,
                    author: quoteData.author,
                    collection: quoteData.collection,
                )

                // Precompute runic transliterations
                quote.runicElder = self.transliterator.transliterate(quoteData.textLatin, to: .elder)
                quote.runicYounger = self.transliterator.transliterate(quoteData.textLatin, to: .younger)
                quote.runicCirth = self.transliterator.transliterate(quoteData.textLatin, to: .cirth)

                context.insert(quote)
            }

            self.logger.info("Database seeded with \(quoteDataArray.count) quotes")
        }
    }

    // MARK: - Quote Retrieval

    func quoteOfTheDay(for script: RunicScript) throws -> QuoteRecord {
        let context = self.makeContext()
        let quotes = try self.fetchVisibleQuotes(in: context)
        guard !quotes.isEmpty else { throw QuoteRepositoryError.noQuotesAvailable }
        let quote = quotes[AppConstants.dailyQuoteIndex(totalQuotes: quotes.count)]
        try self.ensureTransliteration(for: quote, script: script, in: context)
        return QuoteRecord(from: quote)
    }

    func randomQuote(for script: RunicScript) throws -> QuoteRecord {
        let context = self.makeContext()
        let quotes = try self.fetchVisibleQuotes(in: context)
        guard let quote = quotes.randomElement() else { throw QuoteRepositoryError.noQuotesAvailable }
        try self.ensureTransliteration(for: quote, script: script, in: context)
        return QuoteRecord(from: quote)
    }

    func allQuotes() throws -> [QuoteRecord] {
        try self.fetchVisibleQuotes(in: self.makeContext()).map(QuoteRecord.init(from:))
    }

    func quote(id: UUID) throws -> QuoteRecord? {
        try self.fetchQuote(id: id, in: self.makeContext()).map(QuoteRecord.init(from:))
    }

    func archivedQuotes() throws -> [QuoteRecord] {
        let descriptor = FetchDescriptor<Quote>(
            predicate: #Predicate { $0.isHidden || $0.isSoftDeleted },
            sortBy: [SortDescriptor(\.createdAt)],
        )
        return try self.makeContext().fetch(descriptor).map(QuoteRecord.init(from:))
    }

    // MARK: - Create / Update

    func createQuote(
        textLatin: String,
        author: String,
        source: String?,
        collection: QuoteCollection,
        storedRunic: RunicTextBundle? = nil,
        translations: [TranslationResult] = [],
    ) throws -> QuoteRecord {
        let record = try self.transaction { context in
            let quote = Quote(textLatin: textLatin, author: author, collection: collection, isUserGenerated: true)
            quote.source = source
            self.applyStoredRunic(to: quote, textLatin: textLatin, storedRunic: storedRunic)
            context.insert(quote)
            try SwiftDataTranslationRepository.stage(results: translations, for: quote.id, sourceText: textLatin, in: context)
            return QuoteRecord(from: quote)
        }
        if !translations.isEmpty {
            self.notifyTranslationChange(for: record.id)
        }
        return record
    }

    func updateQuote(
        id: UUID,
        textLatin: String,
        author: String,
        source: String?,
        collection: QuoteCollection,
        storedRunic: RunicTextBundle? = nil,
    ) throws -> QuoteRecord {
        let record = try self.transaction { context in
            let quote = try self.requireQuote(id: id, in: context)
            if quote.textLatin != textLatin {
                try SwiftDataTranslationRepository.stageDeletion(for: id, in: context)
            }
            quote.textLatin = textLatin
            quote.author = author
            quote.source = source
            quote.collection = collection
            self.applyStoredRunic(to: quote, textLatin: textLatin, storedRunic: storedRunic)
            return QuoteRecord(from: quote)
        }
        self.notifyTranslationChange(for: id)
        return record
    }

    func hideQuote(id: UUID) throws -> QuoteRecord {
        try self.transaction { context in
            let quote = try self.requireQuote(id: id, in: context)
            quote.isHidden = true
            quote.isSoftDeleted = false
            quote.deletedAt = nil
            return QuoteRecord(from: quote)
        }
    }

    func softDeleteQuote(id: UUID, deletedAt: Date = Date()) throws -> QuoteRecord {
        try self.transaction { context in
            let quote = try self.requireQuote(id: id, in: context)
            quote.isSoftDeleted = true
            quote.isHidden = false
            quote.deletedAt = deletedAt
            return QuoteRecord(from: quote)
        }
    }

    func restoreQuote(id: UUID) throws -> QuoteRecord {
        try self.transaction { context in
            let quote = try self.requireQuote(id: id, in: context)
            quote.isHidden = false
            quote.isSoftDeleted = false
            quote.deletedAt = nil
            return QuoteRecord(from: quote)
        }
    }

    func eraseQuote(id: UUID) throws {
        try self.transaction { context in
            try context.delete(self.requireQuote(id: id, in: context))
            try SwiftDataTranslationRepository.stageDeletion(for: id, in: context)
            try self.pruneSavedQuotes([id], in: context)
        }
        self.notifyTranslationChange(for: id)
    }

    func purgeDeletedQuotes(before cutoffDate: Date) throws -> Int {
        let ids = try self.transaction { context in
            let descriptor = FetchDescriptor<Quote>(
                predicate: #Predicate { $0.isSoftDeleted && ($0.deletedAt ?? cutoffDate) < cutoffDate },
            )
            let quotes = try context.fetch(descriptor)
            let ids = Set(quotes.map(\.id))
            for quote in quotes {
                let id = quote.id
                context.delete(quote)
                try SwiftDataTranslationRepository.stageDeletion(for: id, in: context)
            }
            try self.pruneSavedQuotes(ids, in: context)
            return ids
        }
        if !ids.isEmpty {
            NotificationCenter.default.post(name: .translationCacheUpdated, object: nil)
        }
        return ids.count
    }

    private func pruneSavedQuotes(_ ids: Set<UUID>, in context: ModelContext) throws {
        guard !ids.isEmpty else { return }
        for preferences in try context.fetch(FetchDescriptor<UserPreferences>()) {
            preferences.savedQuoteIDs.subtract(ids)
        }
    }

    private func notifyTranslationChange(for id: UUID) {
        NotificationCenter.default.post(name: .translationCacheUpdated, object: nil, userInfo: ["quoteID": id])
    }

    private func fetchVisibleQuotes(in context: ModelContext) throws -> [Quote] {
        let descriptor = FetchDescriptor<Quote>(
            predicate: #Predicate { !$0.isHidden && !$0.isSoftDeleted },
            sortBy: [SortDescriptor(\.createdAt)],
        )
        return try context.fetch(descriptor)
    }

    private func fetchQuote(id: UUID, in context: ModelContext) throws -> Quote? {
        var descriptor = FetchDescriptor<Quote>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func requireQuote(id: UUID, in context: ModelContext) throws -> Quote {
        guard let quote = try self.fetchQuote(id: id, in: context) else { throw QuoteRepositoryError.quoteNotFound }
        return quote
    }

    private func applyStoredRunic(to quote: Quote, textLatin: String, storedRunic: RunicTextBundle?) {
        if let storedRunic {
            quote.runicElder = storedRunic.elder
            quote.runicYounger = storedRunic.younger
            quote.runicCirth = storedRunic.cirth
            return
        }

        quote.runicElder = self.transliterator.transliterate(textLatin, to: .elder)
        quote.runicYounger = self.transliterator.transliterate(textLatin, to: .younger)
        quote.runicCirth = self.transliterator.transliterate(textLatin, to: .cirth)
    }

    // MARK: - Private Helpers

    /// Ensure a quote has transliteration for the requested script
    private func ensureTransliteration(for quote: Quote, script: RunicScript, in context: ModelContext) throws {
        var needsSave = false

        switch script {
        case .elder:
            if quote.runicElder == nil {
                quote.runicElder = self.transliterator.transliterate(quote.textLatin, to: .elder)
                needsSave = true
            }
        case .younger:
            if quote.runicYounger == nil {
                quote.runicYounger = self.transliterator.transliterate(quote.textLatin, to: .younger)
                needsSave = true
            }
        case .cirth:
            if quote.runicCirth == nil {
                quote.runicCirth = self.transliterator.transliterate(quote.textLatin, to: .cirth)
                needsSave = true
            }
        }

        if needsSave {
            try self.commit(context)
        }
    }

    /// Seed data row used for initial import and migration backfill.
    private struct SeedQuoteData: Codable {
        let textLatin: String
        let author: String
        let collection: QuoteCollection
    }

    private func decodeSeedData(from data: Data) throws -> [SeedQuoteData] {
        do {
            return try JSONDecoder().decode([SeedQuoteData].self, from: data)
        } catch {
            self.logger.error("Invalid seed data format: \(error.localizedDescription)")
            throw QuoteRepositoryError.invalidSeedData
        }
    }

    /// Repair only unversioned records emitted by the original U+E000–U+E02A mapping.
    /// Explicitly encoded output and Unicode punctuation must never trigger this migration.
    private func migrateLegacyCirthIfNeeded(for quotes: [Quote]) {
        let legacyQuotes = quotes.filter { quote in
            guard quote.cirthEncodingRaw == nil, let cirth = quote.runicCirth else { return false }
            return cirth.unicodeScalars.contains { (0xE000 ... 0xE02A).contains($0.value) }
        }
        guard !legacyQuotes.isEmpty else { return }

        for quote in legacyQuotes {
            quote.runicCirth = self.transliterator.transliterate(quote.textLatin, to: .cirth)
            quote.cirthEncodingRaw = "ANGERTHAS_LATIN_V1"
        }
        self.logger.info("Migrated legacy Cirth encoding for \(legacyQuotes.count) quotes")
    }

    private func backfillCollectionsIfNeeded(for existingQuotes: [Quote], in context: ModelContext) throws {
        let quotesNeedingBackfill = existingQuotes.filter {
            QuoteCollection(rawValue: $0.collectionRaw ?? "") == nil
        }
        guard !quotesNeedingBackfill.isEmpty else { return }

        guard let url = seedDataURL() else {
            throw QuoteRepositoryError.seedDataNotFound
        }
        let data = try Data(contentsOf: url)

        let seedData = try decodeSeedData(from: data)
        let seedCollectionByKey = Dictionary(
            uniqueKeysWithValues: seedData.map {
                (self.seedQuoteKey(textLatin: $0.textLatin, author: $0.author), $0.collection)
            },
        )

        var didUpdate = false

        for quote in quotesNeedingBackfill {
            let key = self.seedQuoteKey(textLatin: quote.textLatin, author: quote.author)
            guard let collection = seedCollectionByKey[key] else { continue }
            quote.collection = collection
            didUpdate = true
        }

        if didUpdate {
            self.logger.info("Backfilled collection tags for existing quotes")
        }
    }

    private func seedQuoteKey(textLatin: String, author: String) -> String {
        "\(self.normalizeSeedField(textLatin))||\(self.normalizeSeedField(author))"
    }

    private func normalizeSeedField(_ value: String) -> String {
        value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Locate seed data in both SwiftPM and app bundle layouts.
    private func seedDataURL() -> URL? {
        #if SWIFT_PACKAGE
            if let packageURL = Bundle.module.url(forResource: "quotes", withExtension: "json") {
                return packageURL
            }
            if let packageSubdirectoryURL = Bundle.module.url(
                forResource: "quotes",
                withExtension: "json",
                subdirectory: "SeedData",
            ) {
                return packageSubdirectoryURL
            }
        #endif
        if let appURL = Bundle.main.url(forResource: "quotes", withExtension: "json") {
            return appURL
        }
        if let appSeedSubdirectoryURL = Bundle.main.url(
            forResource: "quotes",
            withExtension: "json",
            subdirectory: "SeedData",
        ) {
            return appSeedSubdirectoryURL
        }
        if let appResourcesSeedURL = Bundle.main.url(
            forResource: "quotes",
            withExtension: "json",
            subdirectory: "Resources/SeedData",
        ) {
            return appResourcesSeedURL
        }

        return nil
    }
}

// swiftlint:enable type_body_length

// MARK: - Errors

enum QuoteRepositoryError: LocalizedError {
    case seedDataNotFound
    case noQuotesAvailable
    case invalidSeedData
    case quoteNotFound

    var errorDescription: String? {
        switch self {
        case .seedDataNotFound:
            "Could not find seed data file (quotes.json)"
        case .noQuotesAvailable:
            "No quotes available in the database"
        case .invalidSeedData:
            "Seed data is invalid or missing collection tags"
        case .quoteNotFound:
            "Quote not found"
        }
    }
}

// swiftlint:enable function_parameter_count
// swiftlint:enable file_length
