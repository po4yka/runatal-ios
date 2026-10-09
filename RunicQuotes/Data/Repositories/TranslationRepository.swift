//
//  TranslationRepository.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import Foundation
import os
import SwiftData

protocol TranslationRepository: Sendable {
    func latestTranslation(for quoteID: UUID, script: RunicScript) throws -> TranslationResult?
    func latestTranslations(for quoteIDs: [UUID], script: RunicScript) throws -> [UUID: TranslationResult]
    func cache(result: TranslationResult, for quoteID: UUID, sourceText: String) throws
    func cache(results: [TranslationResult], for quoteID: UUID, sourceText: String) throws
    func deleteTranslations(for quoteID: UUID) throws
    func backfillAllQuotes() async throws
}

final class SwiftDataTranslationRepository: TranslationRepository, @unchecked Sendable {
    private static let logger = Logger(subsystem: AppConstants.loggingSubsystem, category: "TranslationCache")
    private let modelContainer: ModelContainer
    private let translationService: HistoricalTranslationService

    init(
        modelContext: ModelContext,
        translationService: HistoricalTranslationService = HistoricalTranslationService(),
    ) {
        self.modelContainer = modelContext.container
        self.translationService = translationService
    }

    private func makeContext() -> ModelContext {
        let context = ModelContext(self.modelContainer)
        context.autosaveEnabled = false
        return context
    }

    func latestTranslation(for quoteID: UUID, script: RunicScript) throws -> TranslationResult? {
        try self.latestTranslations(for: [quoteID], script: script)[quoteID]
    }

    func latestTranslations(for quoteIDs: [UUID], script: RunicScript) throws -> [UUID: TranslationResult] {
        guard !quoteIDs.isEmpty else { return [:] }
        let context = self.makeContext()
        let quotes = try context.fetch(FetchDescriptor<Quote>(predicate: #Predicate { quoteIDs.contains($0.id) && !$0.isSoftDeleted }))
        let byID = Dictionary(uniqueKeysWithValues: quotes.map { ($0.id, $0) })
        let scriptRaw = script.rawValue
        let engineVersion = self.translationService.engineVersion(for: script)
        let datasetVersion = self.translationService.datasetVersion
        let records = try context.fetch(FetchDescriptor<TranslationRecord>(predicate: #Predicate {
            quoteIDs.contains($0.quoteID) && $0.scriptRaw == scriptRaw && $0.engineVersion == engineVersion && $0.datasetVersion == datasetVersion
        }, sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]))
        var results: [UUID: TranslationResult] = [:]
        var repairedIDs: Set<UUID> = []
        for record in records {
            guard results[record.quoteID] == nil, !repairedIDs.contains(record.quoteID),
                  let quote = byID[record.quoteID], record.sourceText == quote.textLatin else { continue }
            do {
                results[record.quoteID] = try record.decodedResult()
            } catch is DecodingError {
                results[record.quoteID] = try self.recoverInvalidRecord(record, in: context)
                repairedIDs.insert(record.quoteID)
            } catch is TranslationRecordError {
                results[record.quoteID] = try self.recoverInvalidRecord(record, in: context)
                repairedIDs.insert(record.quoteID)
            }
        }
        if context.hasChanges {
            try context.save()
            let info: [AnyHashable: Any]? = repairedIDs.count == 1 ? ["quoteID": repairedIDs.first as Any] : nil
            NotificationCenter.default.post(name: .translationCacheUpdated, object: nil, userInfo: info)
        }
        return results
    }

    private func recoverInvalidRecord(_ record: TranslationRecord, in context: ModelContext) throws -> TranslationResult? {
        Self.logger.error("Discarding malformed derived translation cache record")
        let quoteID = record.quoteID
        let script = record.script
        let fidelity = record.fidelity
        let variant = record.requestedVariant ?? .longBranch
        context.delete(record)
        var descriptor = FetchDescriptor<Quote>(predicate: #Predicate { $0.id == quoteID })
        descriptor.fetchLimit = 1
        var regenerated: TranslationResult?
        if let quote = try context.fetch(descriptor).first {
            quote.translationBackfillSignature = nil
            quote.translationBackfillSourceText = nil
            if !quote.isSoftDeleted {
                let result = self.translationService.translate(text: quote.textLatin, script: script, fidelity: fidelity, youngerVariant: variant)
                try Self.stage(results: [result], for: quoteID, sourceText: quote.textLatin, in: context)
                if result.isAvailable {
                    regenerated = result
                }
            }
        }
        return regenerated
    }

    func cache(result: TranslationResult, for quoteID: UUID, sourceText: String) throws {
        try self.cache(results: [result], for: quoteID, sourceText: sourceText)
    }

    func cache(results: [TranslationResult], for quoteID: UUID, sourceText: String) throws {
        let context = self.makeContext()
        try Self.stage(results: results, for: quoteID, sourceText: sourceText, in: context)
        try context.save()
        NotificationCenter.default.post(name: .translationCacheUpdated, object: nil, userInfo: ["quoteID": quoteID])
    }

    static func stage(results: [TranslationResult], for quoteID: UUID, sourceText: String, in context: ModelContext) throws {
        for result in results {
            try self.stage(result: result, for: quoteID, sourceText: sourceText, in: context)
        }
    }

    private static func stage(result: TranslationResult, for quoteID: UUID, sourceText: String, in context: ModelContext) throws {
        guard result.sourceText == sourceText else { throw TranslationCacheError.sourceChanged }
        var quoteDescriptor = FetchDescriptor<Quote>(predicate: #Predicate { $0.id == quoteID })
        quoteDescriptor.fetchLimit = 1
        guard let quote = try context.fetch(quoteDescriptor).first else { throw QuoteRepositoryError.quoteNotFound }
        guard quote.textLatin == sourceText else { throw TranslationCacheError.sourceChanged }
        guard result.confidence.isFinite else { throw TranslationRecordError.invalidMetadata }

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

        if let existing = try context.fetch(descriptor).first {
            existing.sourceText = sourceText
            existing.derivationKindRaw = result.derivationKind.rawValue
            existing.historicalStageRaw = result.historicalStage.rawValue
            existing.createdAt = result.createdAt
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
            let record = try TranslationRecord(result: result, quoteID: quoteID)
            record.updatedAt = Date()
            context.insert(record)
        }

    }

    func deleteTranslations(for quoteID: UUID) throws {
        let context = self.makeContext()
        try Self.stageDeletion(for: quoteID, in: context)
        try context.save()
        NotificationCenter.default.post(name: .translationCacheUpdated, object: nil, userInfo: ["quoteID": quoteID])
    }

    static func stageDeletion(for quoteID: UUID, in context: ModelContext) throws {
        let descriptor = FetchDescriptor<TranslationRecord>(predicate: #Predicate { $0.quoteID == quoteID })
        for record in try context.fetch(descriptor) {
            context.delete(record)
        }
    }

    func backfillAllQuotes() async throws {
        try await TranslationBackfillWorker(modelContainer: self.modelContainer, translationService: self.translationService).run()
    }

}

enum TranslationCacheError: Error {
    case sourceChanged
}
