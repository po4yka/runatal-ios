//
//  TranslationRepositoryTests.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

@testable import RunicQuotes
import SwiftData
import XCTest

final class TranslationRepositoryTests: XCTestCase {
    private var modelContainer: ModelContainer?
    private var modelContext: ModelContext?
    private var quoteRepository: SwiftDataQuoteRepository?
    private var translationRepository: SwiftDataTranslationRepository?

    override func setUpWithError() throws {
        let schema = Schema([Quote.self, UserPreferences.self, TranslationRecord.self, TranslationBackfillState.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: config)
        self.modelContainer = container
        let context = ModelContext(container)
        self.modelContext = context
        self.quoteRepository = SwiftDataQuoteRepository(modelContext: context)
        self.translationRepository = SwiftDataTranslationRepository(modelContext: context)
    }

    override func tearDownWithError() throws {
        self.modelContainer = nil
        self.modelContext = nil
        self.quoteRepository = nil
        self.translationRepository = nil
    }

    func testCacheAndLatestTranslationRoundTrip() throws {
        let quote = try XCTUnwrap(quoteRepository).createQuote(
            textLatin: "The wolf hunts at night",
            author: "Runatal",
            source: nil,
            collection: .motivation,
            storedRunic: nil,
        )
        let result = HistoricalTranslationService().translate(
            text: quote.textLatin,
            script: .younger,
            fidelity: .strict,
            youngerVariant: .longBranch,
        )

        try XCTUnwrap(self.translationRepository).cache(result: result, for: quote.id, sourceText: quote.textLatin)
        let cached = try XCTUnwrap(try XCTUnwrap(translationRepository).latestTranslation(for: quote.id, script: .younger))

        XCTAssertEqual(cached.glyphOutput, result.glyphOutput)
        XCTAssertEqual(cached.engineVersion, result.engineVersion)
        XCTAssertEqual(cached.datasetVersion, result.datasetVersion)
        XCTAssertEqual(cached.evidenceTier, result.evidenceTier)
        XCTAssertEqual(cached.supportLevel, result.supportLevel)
    }

    func testDeleteTranslationsRemovesCachedEntries() throws {
        let quote = try XCTUnwrap(quoteRepository).createQuote(
            textLatin: "The wolf hunts at night",
            author: "Runatal",
            source: nil,
            collection: .motivation,
            storedRunic: nil,
        )
        let result = HistoricalTranslationService().translate(
            text: quote.textLatin,
            script: .elder,
            fidelity: .strict,
        )

        try XCTUnwrap(self.translationRepository).cache(result: result, for: quote.id, sourceText: quote.textLatin)
        XCTAssertNotNil(try XCTUnwrap(self.translationRepository).latestTranslation(for: quote.id, script: .elder))

        try XCTUnwrap(self.translationRepository).deleteTranslations(for: quote.id)

        XCTAssertNil(try XCTUnwrap(self.translationRepository).latestTranslation(for: quote.id, script: .elder))
    }
}
