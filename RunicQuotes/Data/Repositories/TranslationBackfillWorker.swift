//
//  TranslationBackfillWorker.swift
//  RunicQuotes
//
//  Created by Claude on 09.10.26.
//

import Foundation
import SwiftData

/// Rebuilds derived data in bounded, resumable transactions without holding model instances across yields.
struct TranslationBackfillWorker {
    typealias Commit = @Sendable (ModelContext) throws -> Void

    let modelContainer: ModelContainer
    let translationService: HistoricalTranslationService
    var batchSize = 32
    var commit: Commit = { try $0.save() }

    func run() async throws {
        guard self.batchSize > 0 else { throw TranslationBackfillError.invalidBatchSize }
        try Task.checkCancellation()
        self.translationService.warmUp()
        let version = self.translationService.versionSignature
        let dataset = self.translationService.datasetVersion
        let signature = "\(version)|\(dataset)"
        while true {
            try Task.checkCancellation()
            if try self.processBatch(version: version, dataset: dataset, signature: signature) {
                return
            }
            await Task.yield()
        }
    }

    private func processBatch(version: String, dataset: String, signature: String) throws -> Bool {
        let context = ModelContext(self.modelContainer)
        context.autosaveEnabled = false
        do {
            var pending = self.pendingDescriptor(signature: signature)
            let pendingCount = try context.fetchCount(pending)
            pending.fetchLimit = self.batchSize
            let quotes = try context.fetch(pending)
            let state = try self.state(in: context)
            let completedCount = try context.fetchCount(self.completedDescriptor(signature: signature))
            if quotes.isEmpty && state.isCompleted && state.engineVersion == version && state.datasetVersion == dataset {
                return true
            }
            state.engineVersion = version
            state.datasetVersion = dataset
            if state.startedAt == nil || state.isCompleted {
                state.startedAt = Date()
            }
            for quote in quotes {
                let elder = self.translationService.translate(text: quote.textLatin, script: .elder, fidelity: .strict)
                let younger = self.translationService.translate(text: quote.textLatin, script: .younger, fidelity: .strict, youngerVariant: .longBranch)
                try SwiftDataTranslationRepository.stage(results: [elder, younger], for: quote.id, sourceText: quote.textLatin, in: context)
                quote.translationBackfillSignature = signature
                quote.translationBackfillSourceText = quote.textLatin
            }
            state.processedCount = completedCount + quotes.count
            state.updatedAt = Date()
            state.isCompleted = pendingCount <= quotes.count
            state.completedAt = state.isCompleted ? Date() : nil
            try self.commit(context)
            NotificationCenter.default.post(name: .translationCacheUpdated, object: nil)
            return state.isCompleted
        } catch {
            context.rollback()
            throw error
        }
    }

    private func pendingDescriptor(signature: String) -> FetchDescriptor<Quote> {
        FetchDescriptor<Quote>(
            predicate: #Predicate {
                !$0.isSoftDeleted && (($0.translationBackfillSignature ?? "") != signature || ($0.translationBackfillSourceText ?? "") != $0.textLatin)
            },
            sortBy: [SortDescriptor(\.createdAt)],
        )
    }

    private func completedDescriptor(signature: String) -> FetchDescriptor<Quote> {
        FetchDescriptor<Quote>(predicate: #Predicate {
            !$0.isSoftDeleted && ($0.translationBackfillSignature ?? "") == signature && ($0.translationBackfillSourceText ?? "") == $0.textLatin
        })
    }

    private func state(in context: ModelContext) throws -> TranslationBackfillState {
        var descriptor = FetchDescriptor<TranslationBackfillState>(predicate: #Predicate { $0.key == "translation-backfill-state" })
        descriptor.fetchLimit = 1
        if let state = try context.fetch(descriptor).first {
            return state
        }
        let state = TranslationBackfillState()
        context.insert(state)
        return state
    }
}

enum TranslationBackfillError: Error {
    case invalidBatchSize
}
