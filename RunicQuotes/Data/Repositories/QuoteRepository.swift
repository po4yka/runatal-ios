//
//  QuoteRepository.swift
//  RunicQuotes
//
//  Created by Claude on 30.09.25.
//

import Foundation
import os
import SwiftData

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
    let storedTranslationMetadataData: Data?
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
        self.storedTranslationMetadataData = quote.storedTranslationMetadataData
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

/// SwiftData implementation of the QuoteRepository
///
/// Safety: each repository instance and its non-Sendable `ModelContext` remain confined
/// to one owning `ModelActor` executor or the UI's main actor. Repository instances
/// must never be shared between those owners; only Sendable DTOs cross the boundary.
final class SwiftDataQuoteRepository: QuoteRepository, @unchecked Sendable {
    typealias Commit = @Sendable (ModelContext) throws -> Void

    private let modelContainer: ModelContainer
    private let commit: Commit
    private let catalogLoader: @Sendable () throws -> [QuoteCatalogEntry]
    private let transliterator = RunicTransliterator.self
    private let logger = Logger(subsystem: AppConstants.loggingSubsystem, category: "Repository")

    init(
        modelContext: ModelContext,
        commit: @escaping Commit = { try $0.save() },
        catalogLoader: @escaping @Sendable () throws -> [QuoteCatalogEntry] = QuoteSeedCatalog.load,
    ) {
        self.modelContainer = modelContext.container
        self.commit = commit
        self.catalogLoader = catalogLoader
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
        let catalog = try self.catalogLoader()
        guard Set(catalog.map(\.id)).count == catalog.count, catalog.allSatisfy({ !$0.id.isEmpty }) else {
            throw QuoteRepositoryError.invalidSeedData
        }
        try self.transaction { context in
            let quotes = try context.fetch(FetchDescriptor<Quote>())
            let receipts = try context.fetch(FetchDescriptor<QuoteSeedReceipt>())
            let preferences = try context.fetch(FetchDescriptor<UserPreferences>())
            let legacyLibrary = try receipts.isEmpty && (
                quotes.contains { $0.builtInID == nil }
                    || preferences.contains { $0.catalogIdentityVersion == nil }
                    || (context.fetchCount(FetchDescriptor<TranslationBackfillState>())) > 0
            )
            if legacyLibrary {
                try self.adoptLegacyLibrary(quotes: quotes, in: context)
            }
            let knownIDs = try Set(context.fetch(FetchDescriptor<QuoteSeedReceipt>()).map(\.seedID))
            for entry in catalog where !knownIDs.contains(entry.id) {
                let quote = Quote(textLatin: entry.textLatin, author: entry.author, collection: entry.collection)
                quote.id = QuoteSeedReceipt.stableQuoteID(for: entry.id)
                quote.builtInID = entry.id
                quote.source = entry.source
                self.applyStoredRunic(to: quote, textLatin: entry.textLatin, storedRunic: nil)
                context.insert(quote)
                context.insert(QuoteSeedReceipt(seedID: entry.id, quoteID: quote.id))
            }
            self.migrateLegacyCirthIfNeeded(for: quotes)
            for preference in preferences {
                preference.catalogIdentityVersion = "v1"
            }
        }
    }

    private func adoptLegacyLibrary(quotes: [Quote], in context: ModelContext) throws {
        let legacy = try QuoteSeedCatalog.legacyIdentities()
        // Unknown edited rows remain intact. Missing baseline IDs are recorded as erased rather than reimported.
        for entry in legacy {
            let key = QuoteSeedCatalog.identity(textLatin: entry.textLatin, author: entry.author)
            let match = quotes.first {
                !$0.isUserGenerated && $0.builtInID == nil
                    && QuoteSeedCatalog.identity(textLatin: $0.textLatin, author: $0.author) == key
            }
            if let match {
                match.builtInID = entry.id
                if QuoteCollection(rawValue: match.collectionRaw ?? "") == nil {
                    match.collection = entry.collection
                }
            }
            context.insert(QuoteSeedReceipt(seedID: entry.id, quoteID: match?.id))
        }
    }

    // MARK: - Quote Retrieval

    func quoteOfTheDay(for script: RunicScript) throws -> QuoteRecord {
        let context = self.makeContext()
        let count = try QuoteQueries.count(in: context)
        guard count > 0 else { throw QuoteRepositoryError.noQuotesAvailable }
        let quote = try QuoteQueries.quote(at: AppConstants.dailyQuoteIndex(totalQuotes: count), in: context)
        try self.ensureTransliteration(for: quote, script: script, in: context)
        return QuoteRecord(from: quote)
    }

    func randomQuote(for script: RunicScript) throws -> QuoteRecord {
        let context = self.makeContext()
        let count = try QuoteQueries.count(in: context)
        guard count > 0 else { throw QuoteRepositoryError.noQuotesAvailable }
        let quote = try QuoteQueries.quote(at: Int.random(in: 0 ..< count), in: context)
        try self.ensureTransliteration(for: quote, script: script, in: context)
        return QuoteRecord(from: quote)
    }

    func allQuotes() throws -> [QuoteRecord] {
        try QuoteQueries.visible(in: self.makeContext()).map(QuoteRecord.init(from:))
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
            let artifacts = translations.filter(\.isAvailable)
            if !artifacts.isEmpty {
                quote.storedTranslationMetadataData = try JSONEncoder().encode(artifacts)
            }
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
                quote.translationBackfillSignature = nil
                quote.translationBackfillSourceText = nil
                try SwiftDataTranslationRepository.stageDeletion(for: id, in: context)
            }
            quote.storedTranslationMetadataData = nil
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
            try self.markCatalogErased([id], in: context)
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
            try self.markCatalogErased(ids, in: context)
            return ids
        }
        if !ids.isEmpty {
            NotificationCenter.default.post(name: .translationCacheUpdated, object: nil)
        }
        return ids.count
    }

    private func markCatalogErased(_ ids: Set<UUID>, in context: ModelContext) throws {
        guard !ids.isEmpty else { return }
        for receipt in try context.fetch(FetchDescriptor<QuoteSeedReceipt>()) {
            if let id = receipt.quoteID, ids.contains(id) {
                receipt.quoteID = nil
            }
        }
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

}

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
