//
//  TranslationModelTests.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import Foundation
@testable import RunicQuotes
import Testing

@Suite(.tags(.model))
struct TranslationRequestAndResultTests {
    @Test
    func translationRequestDefaultsToPrimaryOptions() {
        let request = TranslationRequest(sourceText: "wolf", script: .elder)

        #expect(request.fidelity == .strict)
        #expect(request.youngerVariant == .longBranch)
        #expect(request.sourceLanguage == .english)
        #expect(request.evidenceCap == .fullDataset)
    }

    @Test(arguments: [
        (TranslationResolutionStatus.attested, TranslationSupportLevel.supported, TranslationEvidenceTier.attested),
        (TranslationResolutionStatus.reconstructed, TranslationSupportLevel.supported, TranslationEvidenceTier.reconstructed),
        (TranslationResolutionStatus.approximated, TranslationSupportLevel.partial, TranslationEvidenceTier.approximate),
        (TranslationResolutionStatus.unavailable, TranslationSupportLevel.unsupported, TranslationEvidenceTier.unsupported),
    ])
    func translationResultDefaultsMatchResolutionStatus(
        resolutionStatus: TranslationResolutionStatus,
        supportLevel: TranslationSupportLevel,
        evidenceTier: TranslationEvidenceTier,
    ) {
        let result = TestSupport.makeTranslationResult(
            glyphOutput: resolutionStatus == .unavailable ? "" : "ᛏᛖᛋᛏ",
            resolutionStatus: resolutionStatus,
            supportLevel: nil,
            evidenceTier: nil,
        )

        #expect(result.supportLevel == supportLevel)
        #expect(result.evidenceTier == evidenceTier)
    }

    @Test
    func translationResultAvailabilityAndPrimaryEvidenceUseStructuredFields() {
        let provenance = [
            TranslationProvenanceEntry(
                sourceID: "onp",
                referenceID: "ref",
                label: "ONP",
                role: "lexicon",
                license: "public",
                sourceWork: "Dictionary",
                licenseNote: nil,
                attestationStatus: .attested,
                lemmaAuthorityID: "ONP:1",
                grammaticalClass: "noun",
                historicalStage: "OLD_NORSE",
                regressionID: nil,
                detail: "detail",
                url: nil,
            ),
        ]
        let result = TestSupport.makeTranslationResult(
            glyphOutput: "ᛏᛖᛋᛏ",
            provenance: provenance,
        )

        #expect(result.isAvailable)
        #expect(result.primaryEvidenceLabel == "ONP")
        #expect(result.primaryProvenance?.detail == "detail")
    }

    @Test
    func translationScriptNameMapsScriptsToDatasetNames() {
        #expect(RunicScript.elder.translationScriptName == "ELDER_FUTHARK")
        #expect(RunicScript.younger.translationScriptName == "YOUNGER_FUTHARK")
        #expect(RunicScript.cirth.translationScriptName == "CIRTH")
    }
}

@Suite(.tags(.model))
struct TranslationRecordTests {
    @Test
    func makeCacheKeyIncludesVersioningInputs() throws {
        let quoteID = try #require(UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE"))

        let key = TranslationRecord.makeCacheKey(
            quoteID: quoteID,
            script: .younger,
            fidelity: .strict,
            requestedVariant: YoungerFutharkVariant.shortTwig.rawValue,
            engineVersion: "engine",
            datasetVersion: "dataset",
        )

        #expect(key == "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee|Younger Futhark|STRICT|SHORT_TWIG|engine|dataset")
    }

    @Test
    func recordRoundTripsStructuredResult() {
        let quoteID = UUID()
        let result = TestSupport.makeTranslationResult(
            script: .younger,
            fidelity: .readable,
            normalizedForm: "ulfR",
            diplomaticForm: "u·l·f·R",
            glyphOutput: "ᚢᛚᚠᛦ",
            requestedVariant: YoungerFutharkVariant.shortTwig.rawValue,
            notes: ["note"],
            unresolvedTokens: ["signal"],
            attestationRefs: ["ref-1"],
            userFacingWarnings: ["warning"],
        )

        let record = TranslationRecord(result: result, quoteID: quoteID)

        #expect(record.quoteID == quoteID)
        #expect(record.script == RunicScript.younger)
        #expect(record.fidelity == TranslationFidelity.readable)
        #expect(record.requestedVariant == YoungerFutharkVariant.shortTwig)
        #expect(record.result.glyphOutput == "ᚢᛚᚠᛦ")
        #expect(record.result.notes == ["note"])
        #expect(record.result.unresolvedTokens == ["signal"])
        #expect(record.result.attestationRefs == ["ref-1"])
        #expect(record.result.userFacingWarnings == ["warning"])
    }
}
