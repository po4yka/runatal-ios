//
//  TranslationRepository.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import Foundation
import SwiftData

protocol TranslationRepository: Sendable {
    func latestTranslation(for quoteID: UUID, script: RunicScript) throws -> TranslationResult?
    func cache(result: TranslationResult, for quoteID: UUID, sourceText: String) throws
    func cache(results: [TranslationResult], for quoteID: UUID, sourceText: String) throws
    func deleteTranslations(for quoteID: UUID) throws
    func backfillAllQuotes() throws
}

final class SwiftDataTranslationRepository: TranslationRepository, @unchecked Sendable {
    private let modelContext: ModelContext
    private let translationService: HistoricalTranslationService

    init(
        modelContext: ModelContext,
        translationService: HistoricalTranslationService = HistoricalTranslationService(),
    ) {
        self.modelContext = modelContext
        self.translationService = translationService
    }

    func latestTranslation(for quoteID: UUID, script: RunicScript) throws -> TranslationResult? {
        var descriptor = FetchDescriptor<TranslationRecord>(
            predicate: #Predicate {
                $0.quoteID == quoteID && $0.scriptRaw == script.rawValue
            },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)],
        )
        descriptor.fetchLimit = 1
        guard let record = try modelContext.fetch(descriptor).first else {
            return nil
        }
        return record.result.withSourceText("")
    }

    func cache(result: TranslationResult, for quoteID: UUID, sourceText: String) throws {
        guard result.resolutionStatus != .unavailable else { return }

        let cacheKey = TranslationRecord.makeCacheKey(
            quoteID: quoteID,
            script: result.script,
            fidelity: result.fidelity,
            requestedVariant: result.requestedVariant,
            engineVersion: result.engineVersion,
            datasetVersion: result.datasetVersion,
        )

        var descriptor = FetchDescriptor<TranslationRecord>(
            predicate: #Predicate { $0.cacheKey == cacheKey },
        )
        descriptor.fetchLimit = 1

        if let existing = try modelContext.fetch(descriptor).first {
            existing.normalizedForm = result.normalizedForm
            existing.diplomaticForm = result.diplomaticForm
            existing.glyphOutput = result.glyphOutput
            existing.resolutionStatusRaw = result.resolutionStatus.rawValue
            existing.supportLevelRaw = result.supportLevel.rawValue
            existing.evidenceTierRaw = result.evidenceTier.rawValue
            existing.confidence = result.confidence
            existing.notesData = try JSONEncoder().encode(result.notes)
            existing.unresolvedTokensData = try JSONEncoder().encode(result.unresolvedTokens)
            existing.provenanceData = try JSONEncoder().encode(result.provenance)
            existing.tokenBreakdownData = try JSONEncoder().encode(result.tokenBreakdown)
            existing.attestationRefsData = try JSONEncoder().encode(result.attestationRefs)
            existing.inputLanguageRaw = result.inputLanguage.rawValue
            existing.userFacingWarningsData = try JSONEncoder().encode(result.userFacingWarnings)
            existing.updatedAt = Date()
        } else {
            self.modelContext.insert(TranslationRecord(result: result.withSourceText(sourceText), quoteID: quoteID))
        }

        try self.modelContext.save()
        NotificationCenter.default.post(name: .translationCacheUpdated, object: nil, userInfo: ["quoteID": quoteID])
    }

    func cache(results: [TranslationResult], for quoteID: UUID, sourceText: String) throws {
        for result in results where result.resolutionStatus != .unavailable {
            try cache(result: result, for: quoteID, sourceText: sourceText)
        }
    }

    func deleteTranslations(for quoteID: UUID) throws {
        let descriptor = FetchDescriptor<TranslationRecord>(
            predicate: #Predicate { $0.quoteID == quoteID },
        )
        for record in try self.modelContext.fetch(descriptor) {
            self.modelContext.delete(record)
        }
        try self.modelContext.save()
        NotificationCenter.default.post(name: .translationCacheUpdated, object: nil, userInfo: ["quoteID": quoteID])
    }

    func backfillAllQuotes() throws {
        self.translationService.warmUp()

        let state = try fetchOrCreateBackfillState()
        let versionSignature = self.translationService.versionSignature
        let datasetVersion = self.translationService.datasetVersion
        if state.isCompleted && state.engineVersion == versionSignature && state.datasetVersion == datasetVersion {
            return
        }

        state.engineVersion = versionSignature
        state.datasetVersion = datasetVersion
        state.processedCount = 0
        state.startedAt = Date()
        state.updatedAt = Date()
        state.completedAt = nil
        state.isCompleted = false
        try self.modelContext.save()

        let descriptor = FetchDescriptor<Quote>(sortBy: [SortDescriptor(\.createdAt)])
        let quotes = try modelContext.fetch(descriptor)

        for quote in quotes where !quote.isSoftDeleted {
            let elder = translationService.translate(
                text: quote.textLatin,
                script: .elder,
                fidelity: .strict,
            )
            let younger = translationService.translate(
                text: quote.textLatin,
                script: .younger,
                fidelity: .strict,
                youngerVariant: .longBranch,
            )
            try cache(results: [elder, younger], for: quote.id, sourceText: quote.textLatin)
            state.processedCount += 1
            state.updatedAt = Date()
        }

        state.isCompleted = true
        state.completedAt = Date()
        state.updatedAt = Date()
        try self.modelContext.save()
        NotificationCenter.default.post(name: .translationCacheUpdated, object: nil)
    }

    private func fetchOrCreateBackfillState() throws -> TranslationBackfillState {
        var descriptor = FetchDescriptor<TranslationBackfillState>(
            predicate: #Predicate { $0.key == "translation-backfill-state" },
        )
        descriptor.fetchLimit = 1
        if let state = try modelContext.fetch(descriptor).first {
            return state
        }
        let state = TranslationBackfillState()
        self.modelContext.insert(state)
        try self.modelContext.save()
        return state
    }
}

private extension TranslationResult {
    func withSourceText(_ sourceText: String) -> TranslationResult {
        TranslationResult(
            sourceText: sourceText,
            script: script,
            fidelity: fidelity,
            derivationKind: derivationKind,
            historicalStage: historicalStage,
            normalizedForm: normalizedForm,
            diplomaticForm: diplomaticForm,
            glyphOutput: glyphOutput,
            requestedVariant: requestedVariant,
            resolutionStatus: resolutionStatus,
            supportLevel: supportLevel,
            evidenceTier: evidenceTier,
            confidence: confidence,
            notes: notes,
            unresolvedTokens: unresolvedTokens,
            provenance: provenance,
            tokenBreakdown: tokenBreakdown,
            attestationRefs: attestationRefs,
            inputLanguage: inputLanguage,
            userFacingWarnings: userFacingWarnings,
            engineVersion: engineVersion,
            datasetVersion: datasetVersion,
            createdAt: createdAt,
            updatedAt: updatedAt,
        )
    }
}
