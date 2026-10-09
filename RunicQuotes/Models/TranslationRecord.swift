//
//  TranslationRecord.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import Foundation
import SwiftData

/// Cached structured translation keyed by quote, script, fidelity, variant, and versioning.
@Model
final class TranslationRecord {
    @Attribute(.unique) var cacheKey: String
    var quoteID: UUID
    var sourceText: String = ""
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
        updatedAt: Date,
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
    convenience init(result: TranslationResult, quoteID: UUID) throws {
        try self.init(
            cacheKey: Self.makeCacheKey(
                quoteID: quoteID,
                script: result.script,
                fidelity: result.fidelity,
                requestedVariant: result.requestedVariant,
                engineVersion: result.engineVersion,
                datasetVersion: result.datasetVersion,
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
            updatedAt: result.updatedAt,
        )
        self.sourceText = result.sourceText
    }

    var script: RunicScript {
        RunicScript(rawValue: self.scriptRaw) ?? .elder
    }

    var fidelity: TranslationFidelity {
        TranslationFidelity(rawValue: self.fidelityRaw) ?? .strict
    }

    var requestedVariant: YoungerFutharkVariant? {
        self.requestedVariantRaw.flatMap(YoungerFutharkVariant.init(rawValue:))
    }

    func decodedResult() throws -> TranslationResult {
        guard let script = RunicScript(rawValue: self.scriptRaw),
              let fidelity = TranslationFidelity(rawValue: self.fidelityRaw),
              let derivation = TranslationDerivationKind(rawValue: self.derivationKindRaw),
              let stage = HistoricalStage(rawValue: self.historicalStageRaw),
              let status = TranslationResolutionStatus(rawValue: self.resolutionStatusRaw),
              let support = TranslationSupportLevel(rawValue: self.supportLevelRaw),
              let evidence = TranslationEvidenceTier(rawValue: self.evidenceTierRaw),
              let language = TranslationSourceLanguage(rawValue: self.inputLanguageRaw), self.confidence.isFinite
        else {
            throw TranslationRecordError.invalidMetadata
        }
        return try TranslationResult(
            sourceText: self.sourceText,
            script: script,
            fidelity: fidelity,
            derivationKind: derivation,
            historicalStage: stage,
            normalizedForm: self.normalizedForm,
            diplomaticForm: self.diplomaticForm,
            glyphOutput: self.glyphOutput,
            requestedVariant: self.requestedVariantRaw,
            resolutionStatus: status,
            supportLevel: support,
            evidenceTier: evidence,
            confidence: self.confidence,
            notes: Self.decode([String].self, from: self.notesData),
            unresolvedTokens: Self.decode([String].self, from: self.unresolvedTokensData),
            provenance: Self.decode([TranslationProvenanceEntry].self, from: self.provenanceData),
            tokenBreakdown: Self.decode([TranslationTokenBreakdown].self, from: self.tokenBreakdownData),
            attestationRefs: Self.decode([String].self, from: self.attestationRefsData),
            inputLanguage: language,
            userFacingWarnings: Self.decode([String].self, from: self.userFacingWarningsData),
            engineVersion: self.engineVersion,
            datasetVersion: self.datasetVersion,
            createdAt: self.createdAt,
            updatedAt: self.updatedAt,
        )
    }

    // swiftlint:disable:next function_parameter_count
    static func makeCacheKey(
        quoteID: UUID,
        script: RunicScript,
        fidelity: TranslationFidelity,
        requestedVariant: String?,
        engineVersion: String,
        datasetVersion: String,
    ) -> String {
        [
            quoteID.uuidString.lowercased(),
            script.rawValue,
            fidelity.rawValue,
            requestedVariant ?? "NONE",
            engineVersion,
            datasetVersion,
        ].joined(separator: "|")
    }

    private static func encode(_ value: some Encodable) throws -> Data {
        try JSONEncoder().encode(value)
    }

    private static func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        try JSONDecoder().decode(type, from: data)
    }
}

enum TranslationRecordError: Error {
    case invalidMetadata
}
