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
        #expect(RunicFontConfiguration.fontName(for: .elder, font: .cirth) == "Noto Sans Runic")
        #expect(RunicFontConfiguration.fontName(for: .cirth, font: .noto) == "RunatalCirth-Regular")
        #expect(RunicFontConfiguration.fontName(for: .younger, font: .babelstone) == "BabelStone Runic")
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

@MainActor
@Suite(.tags(.utility))
struct AtmosphericGlyphInventoryTests {
    @Test
    func decorationsBelongToTheSelectedApprovedRuneInventory() {
        for script in RunicScript.allCases {
            let glyphs = RunicAtmosphere.glyphCharacters(for: script).joined()
            #expect(!glyphs.isEmpty)
            #expect(HistoricalGlyphInventory.unsupportedGlyphs(in: glyphs, sourceText: "", script: script, variant: .longBranch).isEmpty)
        }
    }
}
