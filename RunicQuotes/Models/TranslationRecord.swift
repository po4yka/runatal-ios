//
//  TranslationRecord.swift
//  RunicQuotes
//
//  Created by Codex on 2026-03-13.
//

import Foundation
import SwiftData

/// Cached structured translation keyed by quote, script, fidelity, variant, and versioning.
@Model
final class TranslationRecord {
    @Attribute(.unique) var cacheKey: String
    var quoteID: UUID
    var scriptRaw: String
    var fidelityRaw: String
    var requestedVariantRaw: String?
    var derivationKindRaw: String
    var historicalStageRaw: String
    var normalizedForm: String
    var diplomaticForm: String
    var glyphOutput: String
    var resolutionStatusRaw: String
    var supportLevelRaw: String = TranslationSupportLevel.supported.rawValue
    var evidenceTierRaw: String = TranslationEvidenceTier.reconstructed.rawValue
    var confidence: Double
    var notesData: Data
    var unresolvedTokensData: Data
    var provenanceData: Data
    var tokenBreakdownData: Data
    var attestationRefsData: Data = Data("[]".utf8)
    var inputLanguageRaw: String = TranslationSourceLanguage.english.rawValue
    var userFacingWarningsData: Data = Data("[]".utf8)
    var engineVersion: String
    var datasetVersion: String
    var createdAt: Date
    var updatedAt: Date

    init(
        cacheKey: String,
        quoteID: UUID,
        scriptRaw: String,
        fidelityRaw: String,
        requestedVariantRaw: String?,
        derivationKindRaw: String,
        historicalStageRaw: String,
        normalizedForm: String,
        diplomaticForm: String,
        glyphOutput: String,
        resolutionStatusRaw: String,
        supportLevelRaw: String,
        evidenceTierRaw: String,
        confidence: Double,
        notesData: Data,
        unresolvedTokensData: Data,
        provenanceData: Data,
        tokenBreakdownData: Data,
        attestationRefsData: Data,
        inputLanguageRaw: String,
        userFacingWarningsData: Data,
        engineVersion: String,
        datasetVersion: String,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.cacheKey = cacheKey
        self.quoteID = quoteID
        self.scriptRaw = scriptRaw
        self.fidelityRaw = fidelityRaw
        self.requestedVariantRaw = requestedVariantRaw
        self.derivationKindRaw = derivationKindRaw
        self.historicalStageRaw = historicalStageRaw
        self.normalizedForm = normalizedForm
        self.diplomaticForm = diplomaticForm
        self.glyphOutput = glyphOutput
        self.resolutionStatusRaw = resolutionStatusRaw
        self.supportLevelRaw = supportLevelRaw
        self.evidenceTierRaw = evidenceTierRaw
        self.confidence = confidence
        self.notesData = notesData
        self.unresolvedTokensData = unresolvedTokensData
        self.provenanceData = provenanceData
        self.tokenBreakdownData = tokenBreakdownData
        self.attestationRefsData = attestationRefsData
        self.inputLanguageRaw = inputLanguageRaw
        self.userFacingWarningsData = userFacingWarningsData
        self.engineVersion = engineVersion
        self.datasetVersion = datasetVersion
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

extension TranslationRecord {
    convenience init(result: TranslationResult, quoteID: UUID) {
        self.init(
            cacheKey: Self.makeCacheKey(
                quoteID: quoteID,
                script: result.script,
                fidelity: result.fidelity,
                requestedVariant: result.requestedVariant,
                engineVersion: result.engineVersion,
                datasetVersion: result.datasetVersion
            ),
            quoteID: quoteID,
            scriptRaw: result.script.rawValue,
            fidelityRaw: result.fidelity.rawValue,
            requestedVariantRaw: result.requestedVariant,
            derivationKindRaw: result.derivationKind.rawValue,
            historicalStageRaw: result.historicalStage.rawValue,
            normalizedForm: result.normalizedForm,
            diplomaticForm: result.diplomaticForm,
            glyphOutput: result.glyphOutput,
            resolutionStatusRaw: result.resolutionStatus.rawValue,
            supportLevelRaw: result.supportLevel.rawValue,
            evidenceTierRaw: result.evidenceTier.rawValue,
            confidence: result.confidence,
            notesData: Self.encode(result.notes),
            unresolvedTokensData: Self.encode(result.unresolvedTokens),
            provenanceData: Self.encode(result.provenance),
            tokenBreakdownData: Self.encode(result.tokenBreakdown),
            attestationRefsData: Self.encode(result.attestationRefs),
            inputLanguageRaw: result.inputLanguage.rawValue,
            userFacingWarningsData: Self.encode(result.userFacingWarnings),
            engineVersion: result.engineVersion,
            datasetVersion: result.datasetVersion,
            createdAt: result.createdAt,
            updatedAt: result.updatedAt
        )
    }

    var script: RunicScript {
        RunicScript(rawValue: scriptRaw) ?? .elder
    }

    var fidelity: TranslationFidelity {
        TranslationFidelity(rawValue: fidelityRaw) ?? .strict
    }

    var requestedVariant: YoungerFutharkVariant? {
        requestedVariantRaw.flatMap(YoungerFutharkVariant.init(rawValue:))
    }

    var result: TranslationResult {
        TranslationResult(
            sourceText: "",
            script: script,
            fidelity: fidelity,
            derivationKind: TranslationDerivationKind(rawValue: derivationKindRaw) ?? .tokenComposed,
            historicalStage: HistoricalStage(rawValue: historicalStageRaw) ?? .modernEnglish,
            normalizedForm: normalizedForm,
            diplomaticForm: diplomaticForm,
            glyphOutput: glyphOutput,
            requestedVariant: requestedVariantRaw,
            resolutionStatus: TranslationResolutionStatus(rawValue: resolutionStatusRaw) ?? .unavailable,
            supportLevel: TranslationSupportLevel(rawValue: supportLevelRaw) ?? .unsupported,
            evidenceTier: TranslationEvidenceTier(rawValue: evidenceTierRaw) ?? .unsupported,
            confidence: confidence,
            notes: Self.decode([String].self, from: notesData),
            unresolvedTokens: Self.decode([String].self, from: unresolvedTokensData),
            provenance: Self.decode([TranslationProvenanceEntry].self, from: provenanceData),
            tokenBreakdown: Self.decode([TranslationTokenBreakdown].self, from: tokenBreakdownData),
            attestationRefs: Self.decode([String].self, from: attestationRefsData),
            inputLanguage: TranslationSourceLanguage(rawValue: inputLanguageRaw) ?? .english,
            userFacingWarnings: Self.decode([String].self, from: userFacingWarningsData),
            engineVersion: engineVersion,
            datasetVersion: datasetVersion,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    // swiftlint:disable:next function_parameter_count
    static func makeCacheKey(
        quoteID: UUID,
        script: RunicScript,
        fidelity: TranslationFidelity,
        requestedVariant: String?,
        engineVersion: String,
        datasetVersion: String
    ) -> String {
        [
            quoteID.uuidString.lowercased(),
            script.rawValue,
            fidelity.rawValue,
            requestedVariant ?? "NONE",
            engineVersion,
            datasetVersion
        ].joined(separator: "|")
    }

    private static func encode<T: Encodable>(_ value: T) -> Data {
        (try? JSONEncoder().encode(value)) ?? Data("[]".utf8)
    }

    private static func decode<T: Decodable>(_ type: T.Type, from data: Data) -> T {
        if let value = try? JSONDecoder().decode(type, from: data) {
            return value
        }
        let fallback = String(data: data, encoding: .utf8) ?? ""
        if type == [String].self, let value = try? JSONDecoder().decode(type, from: Data(fallback.utf8)) {
            return value
        }
        fatalError("Invalid translation record payload for \(type)")
    }
}
