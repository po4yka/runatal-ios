//
//  CirthEncodingContractTests.swift
//  RunicQuotes
//
//  Created by Claude on 09.10.26.
//

import Foundation
@testable import RunicQuotes
import XCTest

final class CirthEncodingContractTests: XCTestCase {
    func testEreborTranscriptionUsesCanonicalGraphIdentities() {
        // Independent Appendix E / CSUR values, not derived from app tables.
        XCTAssertEqual(RunicTransliterator.transliterate("rjzx", to: .cirth).glyphOutput, "\u{E08B}\u{E08D}\u{E0AB}\u{E090}")
        XCTAssertEqual(RunicTransliterator.transliterate("th dh ch sh ng ll", to: .cirth).glyphOutput, "\u{E089} \u{E08A} \u{E08C} \u{E08E} \u{E0A4} \u{E09E}\u{E09E}")
        XCTAssertEqual(RunicTransliterator.transliterate("khw", to: .cirth).glyphOutput, "\u{E098}")
    }

    func testHistoricalEreborRendererKeepsSegmentBoundariesAndModeValues() {
        let service = HistoricalTranslationService()
        XCTAssertEqual(service.translate(text: "thing", script: .cirth).glyphOutput, "\u{E089}\u{E0A7}\u{E0A4}")
        XCTAssertEqual(service.translate(text: "r j z x ll", script: .cirth).glyphOutput, "\u{E08B} \u{E08D} \u{E0AB} \u{E090} \u{E09E}\u{E09E}")
    }

    func testLegacyMigrationPreservesGraphShapeAndHistoricalReceipt() throws {
        let quote = Quote(textLatin: "different source", author: "Owner", isUserGenerated: true)
        quote.runicCirth = "xçjñ"
        quote.cirthEncodingRaw = "ANGERTHAS_LATIN_V1"
        let original = HistoricalTranslationService().translate(text: "x", script: .cirth)
        XCTAssertTrue(original.isAvailable, "The bundled historical dataset must load before testing artifact migration")
        var payload = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode([original])) as? [[String: Any]])
        payload[0]["glyphOutput"] = "xçjñ"
        payload[0]["engineVersion"] = "cirth-translation-v7"
        var tokens = try XCTUnwrap(payload[0]["tokenBreakdown"] as? [[String: Any]])
        var firstToken = try XCTUnwrap(tokens.first, "A real available Cirth result must expose its token trace")
        firstToken["glyphToken"] = "x"
        tokens[0] = firstToken
        payload[0]["tokenBreakdown"] = tokens
        quote.storedTranslationMetadataData = try JSONSerialization.data(withJSONObject: payload)
        LegacyCirthEncodingMigration.upgrade(quote)
        let expected = "\u{E091}\u{E0B9}\u{E08E}\u{E09C}\u{E0A3}"
        XCTAssertEqual(quote.runicCirth, expected)
        let stored = try JSONDecoder().decode([TranslationResult].self, from: XCTUnwrap(quote.storedTranslationMetadataData))[0]
        XCTAssertEqual(stored.glyphOutput, expected)
        XCTAssertEqual(stored.tokenBreakdown[0].glyphToken, "\u{E091}\u{E0B9}")
        XCTAssertEqual(stored.sourceText, "x")
        XCTAssertEqual(stored.engineVersion, "cirth-translation-v7")
        XCTAssertEqual(stored.provenance, original.provenance)
        XCTAssertEqual(stored.normalizedForm, original.normalizedForm)
        XCTAssertEqual(quote.cirthEncodingRaw, "CIRTH_CSUR_V1")
        let once = quote.storedTranslationMetadataData
        LegacyCirthEncodingMigration.upgrade(quote)
        XCTAssertEqual(quote.storedTranslationMetadataData, once)
    }

    func testLegacyMigrationKeepsUnknownExplicitEncodings() {
        let quote = Quote(textLatin: "x", author: "Owner")
        quote.runicCirth = "EXACT-OUTPUT"
        quote.cirthEncodingRaw = "OTHER_EXPLICIT_FONT"
        LegacyCirthEncodingMigration.upgrade(quote)
        XCTAssertEqual(quote.runicCirth, "EXACT-OUTPUT")
        XCTAssertEqual(quote.cirthEncodingRaw, "OTHER_EXPLICIT_FONT")
    }

    func testCirthMigrationRetainsCorruptedPermanentMetadataBytes() {
        let quote = Quote(textLatin: "different source", author: "Owner")
        quote.runicCirth = "x"
        quote.cirthEncodingRaw = "ANGERTHAS_LATIN_V1"
        let opaque = Data([0xFF, 0x00, 0x42])
        quote.storedTranslationMetadataData = opaque
        LegacyCirthEncodingMigration.upgrade(quote)
        XCTAssertEqual(quote.runicCirth, "\u{E091}\u{E0B9}")
        XCTAssertEqual(quote.storedTranslationMetadataData, opaque)
        XCTAssertEqual(quote.cirthEncodingRaw, "CIRTH_CSUR_V1")
    }

    func testCirthMigrationRefreshesExactGeneratedOutputOnly() {
        let generated = Quote(textLatin: "x ch j z", author: "Owner")
        generated.runicCirth = "x ç j z"
        generated.cirthEncodingRaw = "ANGERTHAS_LATIN_V1"
        LegacyCirthEncodingMigration.upgrade(generated)
        XCTAssertEqual(generated.runicCirth, "\u{E090} \u{E08C} \u{E08D} \u{E0AB}")
        let custom = Quote(textLatin: "unrelated", author: "Owner")
        custom.runicCirth = "\u{E00B}\u{E004}"
        custom.cirthEncodingRaw = nil
        LegacyCirthEncodingMigration.upgrade(custom)
        XCTAssertEqual(custom.runicCirth, "\u{E00B}\u{E004}")
        XCTAssertEqual(custom.cirthEncodingRaw, "CIRTH_UNKNOWN_V0")
    }

}
