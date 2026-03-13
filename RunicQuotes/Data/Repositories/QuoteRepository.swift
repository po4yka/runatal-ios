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
/// Safety: `@unchecked Sendable` because `ModelContext` is not `Sendable`.
/// Thread-safety is guaranteed by only accessing this type from within
/// `QuoteProvider` (an actor) or `@MainActor`-isolated callers.
final class SwiftDataQuoteRepository: QuoteRepository, @unchecked Sendable {
    private let modelContext: ModelContext
    private let translationCacheRepository: TranslationRepository
    private let transliterator = RunicTransliterator.self
    private let logger = Logger(subsystem: AppConstants.loggingSubsystem, category: "Repository")

    init(
        modelContext: ModelContext,
        translationCacheRepository: TranslationRepository? = nil,
    ) {
        self.modelContext = modelContext
        self.translationCacheRepository = translationCacheRepository
            ?? SwiftDataTranslationRepository(modelContext: modelContext)
    }

    // MARK: - Seeding

    func seedIfNeeded() throws {
        // Check if database is already seeded
        let descriptor = FetchDescriptor<Quote>()
        let existingQuotes = try modelContext.fetch(descriptor)

        guard existingQuotes.isEmpty else {
            try self.backfillCollectionsIfNeeded(for: existingQuotes)
            try self.retransliterateCirthIfNeeded(for: existingQuotes)
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

            self.modelContext.insert(quote)
        }

        try self.modelContext.save()
        self.logger.info("Database seeded with \(quoteDataArray.count) quotes")
    }

    // MARK: - Quote Retrieval

    func quoteOfTheDay(for script: RunicScript) throws -> QuoteRecord {
        let allQuotes = try fetchVisibleQuotes()

        guard !allQuotes.isEmpty else {
            throw QuoteRepositoryError.noQuotesAvailable
        }

        let index = AppConstants.dailyQuoteIndex(totalQuotes: allQuotes.count)
        let quote = allQuotes[index]

        // Ensure the quote has the runic transliteration for the requested script
        try ensureTransliteration(for: quote, script: script)

        return QuoteRecord(from: quote)
    }

    func randomQuote(for script: RunicScript) throws -> QuoteRecord {
        let allQuotes = try fetchVisibleQuotes()

        guard !allQuotes.isEmpty else {
            throw QuoteRepositoryError.noQuotesAvailable
        }

        let randomIndex = Int.random(in: 0 ..< allQuotes.count)
        let quote = allQuotes[randomIndex]

        // Ensure the quote has the runic transliteration for the requested script
        try ensureTransliteration(for: quote, script: script)

        return QuoteRecord(from: quote)
    }

    func allQuotes() throws -> [QuoteRecord] {
        try self.fetchVisibleQuotes().map(QuoteRecord.init(from:))
    }

    func quote(id: UUID) throws -> QuoteRecord? {
        try self.fetchQuote(id: id).map(QuoteRecord.init(from:))
    }

    func archivedQuotes() throws -> [QuoteRecord] {
        let descriptor = FetchDescriptor<Quote>(
            predicate: #Predicate { $0.isHidden || $0.isSoftDeleted },
            sortBy: [SortDescriptor(\.createdAt)],
        )
        return try self.modelContext.fetch(descriptor).map(QuoteRecord.init(from:))
    }

    // MARK: - Create / Update

    func createQuote(
        textLatin: String,
        author: String,
        source: String?,
        collection: QuoteCollection,
        storedRunic: RunicTextBundle? = nil,
    ) throws -> QuoteRecord {
        let quote = Quote(
            textLatin: textLatin,
            author: author,
            collection: collection,
            isUserGenerated: true,
        )
        quote.source = source
        self.applyStoredRunic(to: quote, textLatin: textLatin, storedRunic: storedRunic)

        self.modelContext.insert(quote)
        try self.modelContext.save()
        self.logger.info("Created user quote: \(quote.id)")
        return QuoteRecord(from: quote)
    }

    func updateQuote(
        id: UUID,
        textLatin: String,
        author: String,
        source: String?,
        collection: QuoteCollection,
        storedRunic: RunicTextBundle? = nil,
    ) throws -> QuoteRecord {
        var descriptor = FetchDescriptor<Quote>(
            predicate: #Predicate { $0.id == id },
        )
        descriptor.fetchLimit = 1
        guard let quote = try modelContext.fetch(descriptor).first else {
            throw QuoteRepositoryError.quoteNotFound
        }

        let textDidChange = quote.textLatin != textLatin
        quote.textLatin = textLatin
        quote.author = author
        quote.source = source
        quote.collection = collection
        self.applyStoredRunic(to: quote, textLatin: textLatin, storedRunic: storedRunic)

        try self.modelContext.save()
        if textDidChange {
            try self.translationCacheRepository.deleteTranslations(for: id)
        }
        self.logger.info("Updated quote: \(quote.id)")
        return QuoteRecord(from: quote)
    }

    func hideQuote(id: UUID) throws -> QuoteRecord {
        let quote = try requireQuote(id: id)
        quote.isHidden = true
        quote.isSoftDeleted = false
        quote.deletedAt = nil
        try self.modelContext.save()
        return QuoteRecord(from: quote)
    }

    func softDeleteQuote(id: UUID, deletedAt: Date = Date()) throws -> QuoteRecord {
        let quote = try requireQuote(id: id)
        quote.isSoftDeleted = true
        quote.isHidden = false
        quote.deletedAt = deletedAt
        try self.modelContext.save()
        return QuoteRecord(from: quote)
    }

    func restoreQuote(id: UUID) throws -> QuoteRecord {
        let quote = try requireQuote(id: id)
        quote.isHidden = false
        quote.isSoftDeleted = false
        quote.deletedAt = nil
        try self.modelContext.save()
        return QuoteRecord(from: quote)
    }

    func eraseQuote(id: UUID) throws {
        let quote = try requireQuote(id: id)
        self.modelContext.delete(quote)
        try self.modelContext.save()
        try self.translationCacheRepository.deleteTranslations(for: id)
    }

    func purgeDeletedQuotes(before cutoffDate: Date) throws -> Int {
        let descriptor = FetchDescriptor<Quote>(
            predicate: #Predicate { $0.isSoftDeleted && $0.deletedAt != nil },
        )
        let deletedQuotes = try modelContext.fetch(descriptor)
        var purgedCount = 0

        for quote in deletedQuotes {
            guard let deletedAt = quote.deletedAt, deletedAt < cutoffDate else { continue }
            let quoteID = quote.id
            self.modelContext.delete(quote)
            purgedCount += 1
            try self.translationCacheRepository.deleteTranslations(for: quoteID)
        }

        if purgedCount > 0 {
            try self.modelContext.save()
        }

        return purgedCount
    }

    private func fetchVisibleQuotes() throws -> [Quote] {
        let descriptor = FetchDescriptor<Quote>(
            predicate: #Predicate { !$0.isHidden && !$0.isSoftDeleted },
            sortBy: [SortDescriptor(\.createdAt)],
        )
        return try self.modelContext.fetch(descriptor)
    }

    private func fetchQuote(id: UUID) throws -> Quote? {
        var descriptor = FetchDescriptor<Quote>(
            predicate: #Predicate { $0.id == id },
        )
        descriptor.fetchLimit = 1
        return try self.modelContext.fetch(descriptor).first
    }

    private func requireQuote(id: UUID) throws -> Quote {
        guard let quote = try fetchQuote(id: id) else {
            throw QuoteRepositoryError.quoteNotFound
        }
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
    private func ensureTransliteration(for quote: Quote, script: RunicScript) throws {
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
            try self.modelContext.save()
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

    /// Re-transliterate Cirth text when stale PUA codepoints are detected.
    ///
    /// Before commit acdc6a2 the Cirth mapping emitted Private Use Area
    /// characters (U+E000-U+E02A) that the Angerthas Moria font does not
    /// contain, causing emoji fallback rendering. Correct Cirth text only
    /// contains ASCII (U+0000-U+007F) and Latin-1 Supplement digraphs
    /// (max U+00FE). Any scalar above U+00FF signals stale data.
    private func retransliterateCirthIfNeeded(for quotes: [Quote]) throws {
        let needsMigration = quotes.contains { quote in
            guard let cirth = quote.runicCirth else { return false }
            return cirth.unicodeScalars.contains { $0.value > 0x00FF }
        }
        guard needsMigration else { return }

        for quote in quotes {
            quote.runicCirth = self.transliterator.transliterate(quote.textLatin, to: .cirth)
        }
        try self.modelContext.save()
        self.logger.info("Re-transliterated Cirth text for \(quotes.count) quotes (PUA migration)")
    }

    private func backfillCollectionsIfNeeded(for existingQuotes: [Quote]) throws {
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
            try self.modelContext.save()
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
