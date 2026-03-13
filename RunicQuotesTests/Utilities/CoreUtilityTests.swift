//
//  CoreUtilityTests.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import Foundation
@testable import RunicQuotes
import Testing

@Suite(.tags(.utility))
struct AppConstantsTests {
    @Test
    func dailyQuoteIndexIsDeterministicAndBounded() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let first = AppConstants.dailyQuoteIndex(for: date, totalQuotes: 50)
        let second = AppConstants.dailyQuoteIndex(for: date, totalQuotes: 50)

        #expect(first == second)
        #expect(first >= 0)
        #expect(first < 50)
    }

    @Test
    func dailyQuoteIndexReturnsZeroWhenNoQuotesAvailable() {
        #expect(AppConstants.dailyQuoteIndex(for: .now, totalQuotes: 0) == 0)
    }
}

@Suite(.tags(.utility))
struct RunicFontConfigurationTests {
    @Test
    func fontNameUsesFallbackForUnsupportedPairing() {
        #expect(RunicFontConfiguration.fontName(for: .elder, font: .noto) == "Noto Sans Runic")
        #expect(RunicFontConfiguration.fontName(for: .elder, font: .cirth) == "Angerthas Moria")
        #expect(RunicFontConfiguration.fontName(for: .cirth, font: .noto) == "Angerthas Moria")
        #expect(RunicFontConfiguration.serifFontName == "SourceSerif4-Regular")
    }

    @Test
    func recommendedFontAndSupportMirrorScriptCompatibility() {
        #expect(RunicFontConfiguration.recommendedFont(for: .younger) == .noto)
        #expect(RunicFontConfiguration.recommendedFont(for: .cirth) == .cirth)
        #expect(RunicFontConfiguration.supports(font: .babelstone, script: .elder))
        #expect(!RunicFontConfiguration.supports(font: .noto, script: .cirth))
    }
}

@Suite(.tags(.utility))
struct StringSearchTests {
    @Test
    func matchesSearchQueryUsesLocalizedSearch() {
        #expect("Fortune favors the bold".matchesSearchQuery("fortune"))
        #expect(!"Fortune favors the bold".matchesSearchQuery("tolkien"))
    }
}
