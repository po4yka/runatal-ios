//
//  TranslationRepositoryTests.swift
//  RunicQuotesTests
//
//  Created by Codex on 2026-03-13.
//

import SwiftData
import XCTest
@testable import RunicQuotes

final class TranslationRepositoryTests: XCTestCase {
    private var modelContainer: ModelContainer?
    private var modelContext: ModelContext?
    private var quoteRepository: SwiftDataQuoteRepository?
    private var translationRepository: SwiftDataTranslationRepository?

    override func setUpWithError() throws {
        let schema = Schema([Quote.self, UserPreferences.self, TranslationRecord.self, TranslationBackfillState.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: config)
        modelContainer = container
        let context = ModelContext(container)
        modelContext = context
        quoteRepository = SwiftDataQuoteRepository(modelContext: context)
        translationRepository = SwiftDataTranslationRepository(modelContext: context)
    }

    override func tearDownWithError() throws {
        modelContainer = nil
        modelContext = nil
        quoteRepository = nil
        translationRepository = nil
    }

    func testCacheAndLatestTranslationRoundTrip() throws {
        let quote = try XCTUnwrap(quoteRepository).createQuote(
            textLatin: "The wolf hunts at night",
            author: "Runatal",
            source: nil,
            collection: .motivation,
            storedRunic: nil
        )
        let result = HistoricalTranslationService().translate(
            text: quote.textLatin,
            script: .younger,
            fidelity: .strict,
            youngerVariant: .longBranch
        )

        try XCTUnwrap(translationRepository).cache(result: result, for: quote.id, sourceText: quote.textLatin)
        let cached = try XCTUnwrap(try XCTUnwrap(translationRepository).latestTranslation(for: quote.id, script: .younger))

        XCTAssertEqual(cached.glyphOutput, result.glyphOutput)
        XCTAssertEqual(cached.engineVersion, result.engineVersion)
        XCTAssertEqual(cached.datasetVersion, result.datasetVersion)
    }

    func testDeleteTranslationsRemovesCachedEntries() throws {
        let quote = try XCTUnwrap(quoteRepository).createQuote(
            textLatin: "The wolf hunts at night",
            author: "Runatal",
            source: nil,
            collection: .motivation,
            storedRunic: nil
        )
        let result = HistoricalTranslationService().translate(
            text: quote.textLatin,
            script: .elder,
            fidelity: .strict
        )

        try XCTUnwrap(translationRepository).cache(result: result, for: quote.id, sourceText: quote.textLatin)
        XCTAssertNotNil(try XCTUnwrap(translationRepository).latestTranslation(for: quote.id, script: .elder))

        try XCTUnwrap(translationRepository).deleteTranslations(for: quote.id)

        XCTAssertNil(try XCTUnwrap(translationRepository).latestTranslation(for: quote.id, script: .elder))
    }
}
