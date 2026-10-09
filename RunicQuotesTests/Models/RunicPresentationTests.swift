//
//  RunicPresentationTests.swift
//  RunicQuotes
//
//  Created by Claude on 09.10.26.
//

import Foundation
@testable import RunicQuotes
import Testing

@Suite(.tags(.model))
struct RunicPresentationTests {
    @Test
    func explicitUnsupportedCirthEncodingPreservesBytesWithoutClaimingRenderableOutput() {
        let stored = "\u{E001}"
        let result = RunicPresentationResolver.resolve(RunicPresentationInput(
            textLatin: "Old output",
            storedText: stored,
            script: .cirth,
            cirthEncoding: "OTHER_EXPLICIT_FONT",
            savedMetadata: nil,
        ), currentCache: nil)
        #expect(result.text == stored)
        #expect(!result.isRenderable)
        #expect(result.evidenceTier == nil)
        #expect(!result.warnings.isEmpty)
    }

    @Test
    func newerCacheCannotBePairedWithAnOlderQuoteSourceSnapshot() {
        let cache = HistoricalTranslationService().translate(text: "The wolf hunts at night", script: .younger, fidelity: .strict)
        #expect(cache.isAvailable)
        let result = RunicPresentationResolver.resolve(RunicPresentationInput(
            textLatin: "An older passage",
            storedText: nil,
            script: .younger,
            cirthEncoding: nil,
            savedMetadata: nil,
        ), currentCache: cache)
        #expect(result.source == .liveTransliteration)
        #expect(result.evidenceTier == nil)
        #expect(result.text != cache.glyphOutput)
    }

    @Test
    func customCompleteStoredGlyphsDoNotAcquireGeneratedSourceWarnings() {
        let result = RunicPresentationResolver.resolve(RunicPresentationInput(
            textLatin: "Rune 💀",
            storedText: "ᚠᚢᚦ",
            script: .elder,
            cirthEncoding: nil,
            savedMetadata: nil,
        ), currentCache: nil)
        #expect(result.text == "ᚠᚢᚦ")
        #expect(result.source == .savedRunicText)
        #expect(result.warnings.contains { $0.contains("assessment") })
        #expect(!result.warnings.contains { $0.contains("unsupported") || $0.contains("Unconverted") })
    }

    @Test
    func recordedOldYoungerLatinVowelIsPreservedWithCurrentInventoryDisclosure() throws {
        let current = HistoricalTranslationService().translate(text: "The wolf hunts at night", script: .younger, fidelity: .strict)
        #expect(current.isAvailable)
        var object = try #require(try JSONSerialization.jsonObject(with: JSONEncoder().encode(current)) as? [String: Any])
        object["glyphOutput"] = "ᚦú"
        object["engineVersion"] = "previous-engine"
        let data = try JSONSerialization.data(withJSONObject: [object])
        let result = RunicPresentationResolver.resolve(RunicPresentationInput(
            textLatin: current.sourceText,
            storedText: "ᚦú",
            script: .younger,
            cirthEncoding: nil,
            savedMetadata: data,
        ), currentCache: current)
        #expect(result.text == "ᚦú")
        #expect(result.source == .savedHistoricalArtifact)
        #expect(result.warnings.contains { $0.contains("outside the current script inventory") && $0.contains("ú") })
    }
}
