//
//  LegacyGeneratedRuneMigrationTests.swift
//  RunicQuotes
//
//  Created by Claude on 09.10.26.
//

import Foundation
@testable import RunicQuotes
import SwiftData
import XCTest

final class LegacyGeneratedRuneMigrationTests: XCTestCase {
    @MainActor
    func testElderMigrationRepairsGeneratedFieldsAndPreservesOverrides() throws {
        let (repository, context) = try makeRepository()
        let generated = Quote(textLatin: "hokv", author: "Owner", isUserGenerated: true)
        generated.runicElder = "ᚻᚩᚴᚡ"
        generated.runicTransliterationVersion = nil
        let custom = Quote(textLatin: "hokv", author: "Owner", isUserGenerated: true)
        custom.runicElder = "ᚠᛁᛞᛖᛚᛁᛏᚤ"
        custom.runicTransliterationVersion = nil
        let artifact = Quote(textLatin: "hokv", author: "Owner", isUserGenerated: true)
        artifact.runicElder = "ᚻᚩᚴᚡ"
        artifact.storedTranslationMetadataData = try JSONEncoder().encode([HistoricalTranslationService().translate(text: "wolf", script: .elder)])
        artifact.runicTransliterationVersion = nil
        for quote in [generated, custom, artifact] {
            context.insert(quote)
        }
        try context.save()
        try repository.seedIfNeeded()
        XCTAssertTrue(try repository.quote(id: generated.id)?.runicElder == "ᚺᛟᚲᚠ")
        XCTAssertTrue(try repository.quote(id: custom.id)?.runicElder == "ᚠᛁᛞᛖᛚᛁᛏᚤ")
        XCTAssertTrue(try repository.quote(id: artifact.id)?.runicElder == "ᚻᚩᚴᚡ")
    }

    @MainActor
    func testYoungerMigrationRepairsGeneratedFieldsAndPreservesOverrides() throws {
        let (repository, context) = try makeRepository()
        let generated = Quote(textLatin: "admhs", author: "Owner", isUserGenerated: true)
        generated.runicYounger = "ᚨᛞᛗᚻᛊ"
        generated.runicTransliterationVersion = 1
        let custom = Quote(textLatin: "admhs", author: "Owner", isUserGenerated: true)
        custom.runicYounger = "ᚬᛋᚢ"
        custom.runicTransliterationVersion = 1
        context.insert(generated)
        context.insert(custom)
        try context.save()
        try repository.seedIfNeeded()
        XCTAssertEqual(try repository.quote(id: generated.id)?.runicYounger, "ᛅᛏᛘᚼᛋ")
        XCTAssertEqual(try repository.quote(id: custom.id)?.runicYounger, "ᚬᛋᚢ")
    }

    @MainActor
    func testNormalizationMigrationRecoversGeneratedAccentsAndKeepsCustomRunes() throws {
        let (repository, context) = try makeRepository()
        let generated = Quote(textLatin: "café ВОЛК", author: "Owner", isUserGenerated: true)
        generated.runicElder = "ᚲᚨᚠ "
        generated.runicTransliterationVersion = 2
        let custom = Quote(textLatin: "café ВОЛК", author: "Owner", isUserGenerated: true)
        custom.runicElder = "ᚹᛁᛋᛞᛟᛗ"
        custom.runicTransliterationVersion = 2
        context.insert(generated)
        context.insert(custom)
        try context.save()
        try repository.seedIfNeeded()
        XCTAssertEqual(try repository.quote(id: generated.id)?.runicElder, "ᚲᚨᚠᛖ ВОЛК")
        XCTAssertEqual(try repository.quote(id: custom.id)?.runicElder, "ᚹᛁᛋᛞᛟᛗ")
    }

    @MainActor
    func testBootstrapPreservesCorruptArtifactAndUnknownCustomCirth() throws {
        let (repository, context) = try makeRepository()
        let corrupt = Quote(textLatin: "different source", author: "Owner")
        corrupt.runicCirth = "x"
        corrupt.cirthEncodingRaw = "ANGERTHAS_LATIN_V1"
        let opaque = Data([0xFF, 0x00, 0x42])
        corrupt.storedTranslationMetadataData = opaque
        let custom = Quote(textLatin: "the king", author: "Owner")
        custom.runicCirth = "\u{E00B}\u{E003} \u{E004}"
        custom.cirthEncodingRaw = nil
        context.insert(corrupt)
        context.insert(custom)
        try context.save()
        try repository.seedIfNeeded()
        let migrated = try XCTUnwrap(repository.quote(id: corrupt.id))
        XCTAssertEqual(migrated.runicCirth, "\u{E091}\u{E0B9}")
        XCTAssertEqual(migrated.storedTranslationMetadataData, opaque)
        XCTAssertEqual(try repository.quote(id: custom.id)?.runicCirth, "\u{E00B}\u{E003} \u{E004}")
    }

    @MainActor
    private func makeRepository() throws -> (SwiftDataQuoteRepository, ModelContext) {
        let context = try TestSupport.makeModelContext()
        return (SwiftDataQuoteRepository(modelContext: context), context)
    }
}
