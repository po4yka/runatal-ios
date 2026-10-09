//
//  TranslationDatasetValidationTests.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import Foundation
@testable import RunicQuotes
import Testing

@Suite(.tags(.dataset))
struct TranslationDatasetValidationTests {
    private let provider: AssetTranslationDatasetProvider

    init() throws {
        self.provider = try AssetTranslationDatasetProvider()
    }

    @Test
    func datasetManifestDeclaresSourceOfTruthPackage() {
        let manifest = self.provider.datasetManifest()

        #expect(manifest.version == "2026.10-runes-i7")
        #expect(manifest.sourceOfTruthPackage == "TranslationCuration/translation-curation-v1")
    }

    @Test
    func sourceManifestEntriesHaveLicenseNotesAndValidURLs() {
        for source in self.provider.sourceManifest().sources {
            #expect(!(source.licenseNote ?? "").isEmpty)
            #expect(URL(string: source.url) != nil)
        }
    }

    @Test
    func strictEntriesHaveStableIDsAndCitations() {
        let oldNorse = self.provider.oldNorseLexicon()
        let protoNorse = self.provider.protoNorseLexicon()

        #expect(Set(oldNorse.map(\.id)).count == oldNorse.count)
        #expect(Set(protoNorse.map(\.id)).count == protoNorse.count)

        for entry in oldNorse.filter(\.strictEligible) {
            #expect(!entry.citations.isEmpty)
            #expect(entry.inventory.isStrictEligible)
        }

        for entry in protoNorse.filter(\.strictEligible) {
            #expect(!entry.citations.isEmpty)
            #expect(entry.inventory.isStrictEligible)
        }
    }

    @Test
    func dictionaryEntriesUseVerifiedHeadwordsWithoutFabricatedONPIDs() {
        let entries = self.provider.oldNorseLexicon()
        let negation = entries.filter { ["on_eigi", "on_aldri"].contains($0.id) }
        #expect(negation.count == 2)
        #expect(negation.allSatisfy { $0.sourceID == "zoega" && $0.citations == [$0.lemma] })
        #expect(entries.allSatisfy { !($0.lemmaAuthorityID ?? "").hasPrefix("ONP:") })
    }

    @Test
    func goldCorpusBenchmarksReferenceKnownAttestationIDs() {
        let referenceIDs = Set(provider.runicCorpusReferences().map(\.id))
        let goldCorpus = self.provider.goldCorpus()

        #expect(!goldCorpus.benchmarks.isEmpty)

        for benchmark in goldCorpus.benchmarks {
            #expect(!benchmark.id.isEmpty)
            #expect(!benchmark.expectations.isEmpty)

            for expectation in benchmark.expectations {
                for referenceID in expectation.attestationRefs {
                    #expect(referenceIDs.contains(referenceID))
                }
            }
        }
    }
}
