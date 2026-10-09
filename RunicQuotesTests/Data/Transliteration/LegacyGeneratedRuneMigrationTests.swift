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
    private func makeRepository() throws -> (SwiftDataQuoteRepository, ModelContext) {
        let context = try TestSupport.makeModelContext()
        return (SwiftDataQuoteRepository(modelContext: context), context)
    }
}
