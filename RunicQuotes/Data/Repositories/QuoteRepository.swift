//
//  QuoteRepository.swift
//  RunicQuotes
//
//  Created by Claude on 2025-11-15.
//

import Foundation
import SwiftData
import os

/// Sendable snapshot of a Quote model used across actor boundaries.
struct QuoteRecord: Sendable {
    let id: UUID
    let textLatin: String
    let author: String
    let collection: QuoteCollection
    let runicElder: String?
    let runicYounger: String?
    let runicCirth: String?
    let createdAt: Date

    init(from quote: Quote) {
        id = quote.id
        textLatin = quote.textLatin
        author = quote.author
        collection = quote.collection
        runicElder = quote.runicElder
        runicYounger = quote.runicYounger
        runicCirth = quote.runicCirth
        createdAt = quote.createdAt
    }

    func runicText(for script: RunicScript) -> String? {
        switch script {
        case .elder:
            return runicElder
        case .younger:
            return runicYounger
        case .cirth:
            return runicCirth
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
}

/// SwiftData implementation of the QuoteRepository
final class SwiftDataQuoteRepository: QuoteRepository, @unchecked Sendable {
    private let modelContext: ModelContext
    private let transliterator = RunicTransliterator.self
    private let logger = Logger(subsystem: AppConstants.loggingSubsystem, category: "Repository")

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Seeding

    func seedIfNeeded() throws {
        // Check if database is already seeded
        let descriptor = FetchDescriptor<Quote>()
        let existingQuotes = try modelContext.fetch(descriptor)

        guard existingQuotes.isEmpty else {
            try backfillCollectionsIfNeeded(for: existingQuotes)
            logger.info("Database already seeded with \(existingQuotes.count) quotes")
            return
        }

        logger.info("Seeding database with quotes...")

        // Load quotes from JSON
        guard let url = seedDataURL(),
              let data = try? Data(contentsOf: url) else {
            throw QuoteRepositoryError.seedDataNotFound
        }

        let quoteDataArray = try decodeSeedData(from: data)

        // Create Quote objects and transliterate
        for quoteData in quoteDataArray {
            let quote = Quote(
                textLatin: quoteData.textLatin,
                author: quoteData.author,
                collection: quoteData.collection
            )

            // Precompute runic transliterations
            quote.runicElder = transliterator.transliterate(quoteData.textLatin, to: .elder)
            quote.runicYounger = transliterator.transliterate(quoteData.textLatin, to: .younger)
            quote.runicCirth = transliterator.transliterate(quoteData.textLatin, to: .cirth)

            modelContext.insert(quote)
        }

        try modelContext.save()
        logger.info("Database seeded with \(quoteDataArray.count) quotes")
    }

    // MARK: - Quote Retrieval

    func quoteOfTheDay(for script: RunicScript) throws -> QuoteRecord {
        // Use a deterministic algorithm based on the current date
        // This ensures all users see the same quote on the same day
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let daysSinceEpoch = calendar.dateComponents([.day], from: Date(timeIntervalSince1970: 0), to: today).day ?? 0

        let allQuotes = try fetchAllQuotes()

        guard !allQuotes.isEmpty else {
            throw QuoteRepositoryError.noQuotesAvailable
        }

        // Use day count as seed for deterministic "random" selection
        let index = daysSinceEpoch % allQuotes.count
        let quote = allQuotes[index]

        // Ensure the quote has the runic transliteration for the requested script
        try ensureTransliteration(for: quote, script: script)

        return QuoteRecord(from: quote)
    }

    func randomQuote(for script: RunicScript) throws -> QuoteRecord {
        let allQuotes = try fetchAllQuotes()

        guard !allQuotes.isEmpty else {
            throw QuoteRepositoryError.noQuotesAvailable
        }

        let randomIndex = Int.random(in: 0..<allQuotes.count)
        let quote = allQuotes[randomIndex]

        // Ensure the quote has the runic transliteration for the requested script
        try ensureTransliteration(for: quote, script: script)

        return QuoteRecord(from: quote)
    }

    func allQuotes() throws -> [QuoteRecord] {
        try fetchAllQuotes().map(QuoteRecord.init(from:))
    }

    private func fetchAllQuotes() throws -> [Quote] {
        let descriptor = FetchDescriptor<Quote>(
            sortBy: [SortDescriptor(\.createdAt)]
        )
        return try modelContext.fetch(descriptor)
    }

    // MARK: - Private Helpers

    /// Ensure a quote has transliteration for the requested script
    private func ensureTransliteration(for quote: Quote, script: RunicScript) throws {
        var needsSave = false

        switch script {
        case .elder:
            if quote.runicElder == nil {
                quote.runicElder = transliterator.transliterate(quote.textLatin, to: .elder)
                needsSave = true
            }
        case .younger:
            if quote.runicYounger == nil {
                quote.runicYounger = transliterator.transliterate(quote.textLatin, to: .younger)
                needsSave = true
            }
        case .cirth:
            if quote.runicCirth == nil {
                quote.runicCirth = transliterator.transliterate(quote.textLatin, to: .cirth)
                needsSave = true
            }
        }

        if needsSave {
            try modelContext.save()
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
            logger.error("Invalid seed data format: \(error.localizedDescription)")
            throw QuoteRepositoryError.invalidSeedData
        }
    }

    private func backfillCollectionsIfNeeded(for existingQuotes: [Quote]) throws {
        let quotesNeedingBackfill = existingQuotes.filter {
            QuoteCollection(rawValue: $0.collectionRaw ?? "") == nil
        }
        guard !quotesNeedingBackfill.isEmpty else { return }

        guard let url = seedDataURL(),
              let data = try? Data(contentsOf: url) else {
            throw QuoteRepositoryError.seedDataNotFound
        }

        let seedData = try decodeSeedData(from: data)
        let seedCollectionByKey = Dictionary(
            uniqueKeysWithValues: seedData.map {
                (seedQuoteKey(textLatin: $0.textLatin, author: $0.author), $0.collection)
            }
        )

        var didUpdate = false

        for quote in quotesNeedingBackfill {
            let key = seedQuoteKey(textLatin: quote.textLatin, author: quote.author)
            guard let collection = seedCollectionByKey[key] else { continue }
            quote.collection = collection
            didUpdate = true
        }

        if didUpdate {
            try modelContext.save()
            logger.info("Backfilled collection tags for existing quotes")
        }
    }

    private func seedQuoteKey(textLatin: String, author: String) -> String {
        "\(normalizeSeedField(textLatin))||\(normalizeSeedField(author))"
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
            subdirectory: "SeedData"
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
            subdirectory: "SeedData"
        ) {
            return appSeedSubdirectoryURL
        }
        if let appResourcesSeedURL = Bundle.main.url(
            forResource: "quotes",
            withExtension: "json",
            subdirectory: "Resources/SeedData"
        ) {
            return appResourcesSeedURL
        }

        return nil
    }
}

// MARK: - Errors

enum QuoteRepositoryError: LocalizedError {
    case seedDataNotFound
    case noQuotesAvailable
    case invalidSeedData

    var errorDescription: String? {
        switch self {
        case .seedDataNotFound:
            return "Could not find seed data file (quotes.json)"
        case .noQuotesAvailable:
            return "No quotes available in the database"
        case .invalidSeedData:
            return "Seed data is invalid or missing collection tags"
        }
    }
}
