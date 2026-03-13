//
//  QuoteTimelineProviderTests.swift
//  RunicQuotesWidgetTests
//
//  Created by Claude on 2025-11-15.
//

import Foundation
import Testing
@testable import RunicQuotes

/// Widget extension binaries do not export symbols for direct unit testing, so these tests
/// validate the shared RunicQuotes types that power widget behaviour.
@Suite(.tags(.widget))
struct QuoteTimelineProviderTests {
    @Test
    func runicScriptCasesExistAndAreIdentifiable() {
        let scripts: [RunicScript] = [.elder, .younger, .cirth]
        #expect(scripts.count == 3)
        #expect(RunicScript.elder.id == RunicScript.elder.rawValue)
        #expect(RunicScript.younger.id == RunicScript.younger.rawValue)
        #expect(RunicScript.cirth.id == RunicScript.cirth.rawValue)
        #expect(RunicScript.allCases.count == 3)
    }

    @Test
    func dailyQuoteIndexIsStableAndBounded() {
        let stableDate = Date(timeIntervalSinceReferenceDate: 0)
        let stableIndex = AppConstants.dailyQuoteIndex(for: stableDate, totalQuotes: 100)

        #expect(stableIndex == AppConstants.dailyQuoteIndex(for: stableDate, totalQuotes: 100))

        let boundedIndex = AppConstants.dailyQuoteIndex(for: .now, totalQuotes: 50)
        #expect(boundedIndex >= 0)
        #expect(boundedIndex < 50)
    }

    @Test
    func quoteCollectionIncludesAllCase() {
        #expect(!QuoteCollection.allCases.isEmpty)
        #expect(QuoteCollection.allCases.contains(.all))
    }

    @Test
    func deepLinkAndQuoteDataSupportWidgetRoutingAndFallback() throws {
        let parsed = try #require(DeepLink.from(url: DeepLink.openQuote(script: .elder, mode: .daily).url))
        let quote = QuoteData(
            textLatin: "Fortune favors the bold.",
            author: "Virgil",
            runicElder: "ᚠᛟᚱᛏᚢᚾᛖ",
            runicYounger: nil,
            runicCirth: nil
        )

        #expect(parsed == .openQuote(script: .elder, mode: .daily))
        #expect(quote.runicText(for: .elder) == "ᚠᛟᚱᛏᚢᚾᛖ")
        #expect(quote.runicText(for: .younger) == quote.textLatin)
    }
}
