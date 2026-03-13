//
//  TranslationDatasetValidationTests.swift
//  RunicQuotesTests
//
//  Created by Codex on 2026-03-13.
//

import XCTest
@testable import RunicQuotes

final class TranslationDatasetValidationTests: XCTestCase {
    private let provider = AssetTranslationDatasetProvider()

    func testDatasetManifestDeclaresSourceOfTruthPackage() {
        let manifest = provider.datasetManifest()

        XCTAssertEqual(manifest.version, "2026.03-curated-v3")
        XCTAssertEqual(manifest.sourceOfTruthPackage, "TranslationCuration/translation-curation-v1")
    }

    func testSourceManifestEntriesHaveLicenseNotesAndValidURLs() {
        for source in provider.sourceManifest().sources {
            XCTAssertFalse((source.licenseNote ?? "").isEmpty, "Missing license note for source \(source.id)")
            XCTAssertNotNil(URL(string: source.url), "Invalid URL for source \(source.id)")
        }
    }

    func testStrictEntriesHaveStableIDsAndCitations() {
        let oldNorse = provider.oldNorseLexicon()
        let protoNorse = provider.protoNorseLexicon()

        XCTAssertEqual(Set(oldNorse.map(\.id)).count, oldNorse.count)
        XCTAssertEqual(Set(protoNorse.map(\.id)).count, protoNorse.count)

        for entry in oldNorse.filter(\.strictEligible) {
            XCTAssertFalse(entry.citations.isEmpty, "Strict Old Norse entry \(entry.id) requires citations")
            XCTAssertTrue(entry.inventory.isStrictEligible, "Strict Old Norse entry \(entry.id) must be in a strict inventory")
        }

        for entry in protoNorse.filter(\.strictEligible) {
            XCTAssertFalse(entry.citations.isEmpty, "Strict Proto-Norse entry \(entry.id) requires citations")
            XCTAssertTrue(entry.inventory.isStrictEligible, "Strict Proto-Norse entry \(entry.id) must be in a strict inventory")
        }
    }

    func testOnpEntriesExposeLemmaAuthorityIdentifiers() {
        let onpEntries = provider.oldNorseLexicon().filter { $0.sourceID == "onp" }

        XCTAssertFalse(onpEntries.isEmpty, "Expected at least one ONP-backed entry")
        XCTAssertTrue(onpEntries.allSatisfy { ($0.lemmaAuthorityID ?? "").hasPrefix("ONP:") })
    }

    func testGoldCorpusBenchmarksReferenceKnownAttestationIDs() {
        let referenceIDs = Set(provider.runicCorpusReferences().map(\.id))
        let goldCorpus = provider.goldCorpus()

        XCTAssertFalse(goldCorpus.benchmarks.isEmpty)

        for benchmark in goldCorpus.benchmarks {
            XCTAssertFalse(benchmark.id.isEmpty)
            XCTAssertFalse(benchmark.expectations.isEmpty)
            for expectation in benchmark.expectations {
                for referenceID in expectation.attestationRefs {
                    XCTAssertTrue(referenceIDs.contains(referenceID), "Unknown attestation ref \(referenceID) in \(benchmark.id)")
                }
            }
        }
    }
}
