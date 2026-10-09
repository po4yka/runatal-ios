//
//  StrictTranslationDatasetTests.swift
//  RunicQuotes
//
//  Created by Claude on 09.10.26.
//

import Foundation
@testable import RunicQuotes
import XCTest

final class StrictTranslationDatasetTests: XCTestCase {
    private var sourceDirectory: URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("TranslationCuration/source/translation")
    }

    func testAllFourteenBundledAssetFamiliesRejectMissingRequiredMetadata() throws {
        let directory = try self.copyDataset()
        defer { try? FileManager.default.removeItem(at: directory) }
        _ = try AssetTranslationDatasetProvider(resourceDirectory: directory)
        let requirements = [
            ("dataset_manifest.json", ["version"]), ("source_manifest.json", ["sources"]),
            ("old_norse_lexicon.json", ["0", "inventory"]), ("proto_norse_lexicon.json", ["0", "attestationStatus"]),
            ("paradigm_tables.json", ["metadata"]), ("grammar_rules.json", ["pronounFeatures"]),
            ("name_adaptations.json", ["metadata"]), ("fallback_templates.json", ["paraphrasesByStage"]),
            ("erebor_tables.json", ["singleCharacters"]), ("younger_phrase_templates.json", ["0", "resolutionStatus"]),
            ("elder_attested_forms.json", ["0", "inventory"]), ("runic_corpus_refs.json", ["0", "attestationStatus"]),
            ("gold_examples.json", ["0", "results", "0", "confidence"]), ("gold_corpus.json", ["benchmarks"]),
        ]
        XCTAssertEqual(requirements.count, 14)
        for (file, path) in requirements {
            let url = directory.appendingPathComponent(file)
            let original = try Data(contentsOf: url)
            let object = try JSONSerialization.jsonObject(with: original, options: [.mutableContainers])
            try self.remove(path, from: object)
            try JSONSerialization.data(withJSONObject: object).write(to: url)
            XCTAssertThrowsError(try AssetTranslationDatasetProvider(resourceDirectory: directory), file)
            try original.write(to: url)
        }
    }

    func testUnknownEnumsConfidenceAndDanglingReferencesFailClosed() throws {
        let directory = try self.copyDataset()
        defer { try? FileManager.default.removeItem(at: directory) }
        for field in ["inventory", "attestationStatus", "historicalStage"] {
            let url = directory.appendingPathComponent("old_norse_lexicon.json")
            let original = try Data(contentsOf: url)
            let rows = try XCTUnwrap(JSONSerialization.jsonObject(with: original, options: [.mutableContainers]) as? NSMutableArray)
            let row = try XCTUnwrap(rows[0] as? NSMutableDictionary)
            row[field] = "UNVERIFIED_TYPO"
            try JSONSerialization.data(withJSONObject: rows).write(to: url)
            XCTAssertThrowsError(try AssetTranslationDatasetProvider(resourceDirectory: directory), field)
            try original.write(to: url)
        }
        let goldURL = directory.appendingPathComponent("gold_examples.json")
        let goldOriginal = try Data(contentsOf: goldURL)
        let examples = try XCTUnwrap(JSONSerialization.jsonObject(with: goldOriginal, options: [.mutableContainers]) as? NSMutableArray)
        let example = try XCTUnwrap(examples[0] as? NSMutableDictionary)
        let results = try XCTUnwrap(example["results"] as? NSMutableArray)
        let result = try XCTUnwrap(results[0] as? NSMutableDictionary)
        result["confidence"] = 1.25
        try JSONSerialization.data(withJSONObject: examples).write(to: goldURL)
        XCTAssertThrowsError(try AssetTranslationDatasetProvider(resourceDirectory: directory))
        try goldOriginal.write(to: goldURL)
        let referencesURL = directory.appendingPathComponent("runic_corpus_refs.json")
        let rows = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: referencesURL), options: [.mutableContainers]) as? NSMutableArray)
        let row = try XCTUnwrap(rows[0] as? NSMutableDictionary)
        row["sourceId"] = "invented_institution"
        try JSONSerialization.data(withJSONObject: rows).write(to: referencesURL)
        XCTAssertThrowsError(try AssetTranslationDatasetProvider(resourceDirectory: directory))
    }

    func testMalformedDatasetReturnsUnavailableWithoutStoppingModernTranscription() throws {
        let directory = try self.copyDataset()
        defer { try? FileManager.default.removeItem(at: directory) }
        try Data("{broken".utf8).write(to: directory.appendingPathComponent("grammar_rules.json"))
        let service = HistoricalTranslationService(resourceDirectory: directory)
        let result = service.translate(text: "wolf", script: .younger)
        XCTAssertEqual(result.resolutionStatus, .unavailable)
        XCTAssertEqual(result.supportLevel, .unsupported)
        XCTAssertTrue(result.glyphOutput.isEmpty)
        XCTAssertTrue(result.userFacingWarnings.contains { $0.contains("data is unavailable") })
        XCTAssertEqual(RunicTransliterator.transliterate("wolf", to: .elder).glyphOutput, "ᚹᛟᛚᚠ")
    }

    func testPositiveNamedCorpusRetainsRealSourcesAfterMetadataCleanup() throws {
        let provider = try AssetTranslationDatasetProvider()
        let service = HistoricalTranslationService()
        XCTAssertEqual(service.translate(text: "Harja", script: .elder, evidenceCap: .attestedOnly).glyphOutput, "ᚺᚨᚱᛃᚨ")
        let synthetic = try XCTUnwrap(provider.runicCorpusReferences().first { $0.id == "cirth_ref_wolf_night" })
        XCTAssertEqual(synthetic.sourceID, "internal_heuristics")
        XCTAssertTrue(synthetic.label.contains("project-authored"))
        XCTAssertFalse(service.translate(text: "The wolf hunts at night", script: .elder).isAvailable)
    }

    func testValidMetadataWithLatinGoldGlyphFailsStrictInventoryAtServiceBoundary() throws {
        let directory = try self.copyDataset()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("gold_examples.json")
        let examples = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: url), options: [.mutableContainers]) as? NSMutableArray)
        let example = try XCTUnwrap(examples.firstObject as? NSMutableDictionary)
        let results = try XCTUnwrap(example["results"] as? NSMutableArray)
        let result = try XCTUnwrap(results.firstObject as? NSMutableDictionary)
        result["glyphOutput"] = "LATIN"
        try JSONSerialization.data(withJSONObject: examples).write(to: url)
        _ = try AssetTranslationDatasetProvider(resourceDirectory: directory)
        let output = HistoricalTranslationService(resourceDirectory: directory).translate(text: "The wolf hunts at night", script: .younger)
        XCTAssertEqual(output.resolutionStatus, .unavailable)
        XCTAssertTrue(output.glyphOutput.isEmpty)
        XCTAssertTrue(output.tokenBreakdown.isEmpty)
        XCTAssertTrue(output.userFacingWarnings.contains { $0.contains("unsupported rune glyphs") })
    }

    func testValidMetadataWithUnknownLexicalLetterFailsStrictInventoryAtServiceBoundary() throws {
        let directory = try self.copyDataset()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("old_norse_lexicon.json")
        let rows = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: url), options: [.mutableContainers]) as? NSMutableArray)
        let negation = try XCTUnwrap(rows.compactMap { $0 as? NSMutableDictionary }.first { $0["english"] as? String == "not" })
        negation["lemma"] = "λ"
        try JSONSerialization.data(withJSONObject: rows).write(to: url)
        _ = try AssetTranslationDatasetProvider(resourceDirectory: directory)
        let service = HistoricalTranslationService(resourceDirectory: directory)
        let output = service.translate(text: "not", script: .younger)
        XCTAssertEqual(output.resolutionStatus, .unavailable)
        XCTAssertEqual(output.unresolvedTokens, ["λ"])
        XCTAssertTrue(output.glyphOutput.isEmpty)
        XCTAssertTrue(output.userFacingWarnings.contains { $0.contains("unsupported rune glyphs") })
        XCTAssertEqual(service.translate(text: "wolf 2 👩‍💻", script: .younger).glyphOutput, "ᚢᛚᚠᚱ 2 👩‍💻")
    }

    private func copyDataset() throws -> URL {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        for url in try FileManager.default.contentsOfDirectory(at: self.sourceDirectory, includingPropertiesForKeys: nil) where url.pathExtension == "json" {
            try FileManager.default.copyItem(at: url, to: directory.appendingPathComponent(url.lastPathComponent))
        }
        return directory
    }

    private func remove(_ path: [String], from object: Any) throws {
        var current = object
        for component in path.dropLast() {
            if let index = Int(component), let array = current as? NSMutableArray {
                current = array[index]
            } else if let dictionary = current as? NSMutableDictionary, let next = dictionary[component] {
                current = next
            } else {
                throw TranslationDatasetError.invalidMetadata("Test path does not exist")
            }
        }
        let dictionary = try XCTUnwrap(current as? NSMutableDictionary)
        try dictionary.removeObject(forKey: XCTUnwrap(path.last))
    }
}
