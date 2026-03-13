//
//  TranslationDatasetValidationTests.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

@testable import RunicQuotes
import XCTest

final class TranslationDatasetValidationTests: XCTestCase {
    private let provider = AssetTranslationDatasetProvider()

    func testDatasetManifestDeclaresSourceOfTruthPackage() {
        let manifest = self.provider.datasetManifest()

        XCTAssertEqual(manifest.version, "2026.03-curated-v3")
        XCTAssertEqual(manifest.sourceOfTruthPackage, "TranslationCuration/translation-curation-v1")
    }

    func testSourceManifestEntriesHaveLicenseNotesAndValidURLs() {
        for source in self.provider.sourceManifest().sources {
            XCTAssertFalse((source.licenseNote ?? "").isEmpty, "Missing license note for source \(source.id)")
            XCTAssertNotNil(URL(string: source.url), "Invalid URL for source \(source.id)")
        }
    }

    func testStrictEntriesHaveStableIDsAndCitations() {
        let oldNorse = self.provider.oldNorseLexicon()
        let protoNorse = self.provider.protoNorseLexicon()

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
        let onpEntries = self.provider.oldNorseLexicon().filter { $0.sourceID == "onp" }

        XCTAssertFalse(onpEntries.isEmpty, "Expected at least one ONP-backed entry")
        XCTAssertTrue(onpEntries.allSatisfy { ($0.lemmaAuthorityID ?? "").hasPrefix("ONP:") })
    }

    func testGoldCorpusBenchmarksReferenceKnownAttestationIDs() {
        let referenceIDs = Set(provider.runicCorpusReferences().map(\.id))
        let goldCorpus = self.provider.goldCorpus()

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
