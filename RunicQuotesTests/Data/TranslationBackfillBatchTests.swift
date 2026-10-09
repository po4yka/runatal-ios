//
//  TranslationBackfillBatchTests.swift
//  RunicQuotes
//
//  Created by Claude on 09.10.26.
//

import Foundation
@testable import RunicQuotes
import SwiftData
import Testing

@MainActor
@Suite(.serialized, .tags(.repository))
struct TranslationBackfillBatchTests {
    @Test
    func failedBatchPreservesCheckpointAndRetryDoesNotRewriteCompletedQuotes() async throws {
        let context = try TestSupport.makeModelContext()
        for _ in 0 ..< 65 {
            context.insert(Quote(textLatin: "The wolf hunts at night", author: "Audit", isUserGenerated: true))
        }
        try context.save()
        let failure = BackfillCommitFailure()
        let worker = TranslationBackfillWorker(
            modelContainer: context.container,
            translationService: HistoricalTranslationService(),
            commit: { try failure.commit($0) },
        )
        await #expect(throws: TestError.self) { try await worker.run() }
        let persisted = ModelContext(context.container)
        let state = try #require(persisted.fetch(FetchDescriptor<TranslationBackfillState>()).first)
        #expect(state.processedCount == 32)
        #expect(!state.isCompleted)
        let firstRecords = try persisted.fetch(FetchDescriptor<TranslationRecord>())
        #expect(firstRecords.count == 64)
        let timestamps = Dictionary(uniqueKeysWithValues: firstRecords.map { ($0.cacheKey, $0.updatedAt) })
        try await SwiftDataTranslationRepository(modelContext: context).backfillAllQuotes()
        let resumed = ModelContext(context.container)
        let complete = try #require(resumed.fetch(FetchDescriptor<TranslationBackfillState>()).first)
        #expect(complete.isCompleted)
        #expect(complete.processedCount == 65)
        let allRecords = try resumed.fetch(FetchDescriptor<TranslationRecord>())
        #expect(allRecords.count == 130)
        for record in allRecords {
            if let original = timestamps[record.cacheKey] {
                #expect(record.updatedAt == original)
            }
        }
    }

    @Test
    func cancellationStopsBeforeFurtherBatchesWithoutMarkingCompletion() async throws {
        let context = try TestSupport.makeModelContext()
        for _ in 0 ..< 65 {
            context.insert(Quote(textLatin: "The wolf hunts at night", author: "Audit"))
        }
        try context.save()
        let repository = SwiftDataTranslationRepository(modelContext: context)
        let task = Task { try await repository.backfillAllQuotes() }
        task.cancel()
        await #expect(throws: CancellationError.self) { try await task.value }
        let persisted = ModelContext(context.container)
        let state = try persisted.fetch(FetchDescriptor<TranslationBackfillState>()).first
        #expect(state?.isCompleted != true)
        #expect((state?.processedCount ?? 0) <= 32)
    }
}

private final class BackfillCommitFailure: @unchecked Sendable {
    private let lock = NSLock()
    private var calls = 0

    func commit(_ context: ModelContext) throws {
        let call = self.lock.withLock { self.calls += 1; return self.calls }
        if call == 2 {
            throw TestError(message: "Second batch failed")
        }
        try context.save()
    }
}
