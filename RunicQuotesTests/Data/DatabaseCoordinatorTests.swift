//
//  DatabaseCoordinatorTests.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import Foundation
@testable import RunicQuotes
import SwiftData
import Testing

@Suite(.serialized, .tags(.actors))
struct DatabaseCoordinatorTests {
    @Test
    func seedIfNeededCoalescesConcurrentRequests() async throws {
        let container = try makeContainer()
        let quoteRepository = DatabaseQuoteRepositorySpy(seedDelay: 0.05)
        let translationRepository = DatabaseTranslationRepositorySpy()
        let coordinator = DatabaseCoordinator(
            modelContainer: container,
            quoteRepositoryFactory: { _, _ in
                quoteRepository.recordFactoryUse()
                return quoteRepository
            },
            translationRepositoryFactory: { _, _ in translationRepository },
        )

        async let firstSeed: Void = coordinator.seedIfNeeded()
        async let secondSeed: Void = coordinator.seedIfNeeded()
        _ = try await (firstSeed, secondSeed)

        #expect(quoteRepository.seedCallCount == 1)
        #expect(quoteRepository.factoryUseCount == 1)
    }

    @Test
    func seedIfNeededSkipsWorkAfterSuccessfulCompletion() async throws {
        let container = try makeContainer()
        let quoteRepository = DatabaseQuoteRepositorySpy()
        let coordinator = DatabaseCoordinator(
            modelContainer: container,
            quoteRepositoryFactory: { _, _ in
                quoteRepository.recordFactoryUse()
                return quoteRepository
            },
        )

        try await coordinator.seedIfNeeded()
        try await coordinator.seedIfNeeded()

        #expect(quoteRepository.seedCallCount == 1)
        #expect(quoteRepository.factoryUseCount == 1)
    }

    @Test
    func seedIfNeededRetriesFailureThenRemembersSuccess() async throws {
        let container = try makeContainer()
        let quoteRepository = DatabaseQuoteRepositorySpy(seedFailures: 1)
        let coordinator = DatabaseCoordinator(
            modelContainer: container,
            quoteRepositoryFactory: { context, _ in
                quoteRepository.recordFactoryUse(in: context)
                return quoteRepository
            },
        )

        await #expect(throws: DatabaseSeedError.failed) {
            try await coordinator.seedIfNeeded()
        }
        try await coordinator.seedIfNeeded()
        try await coordinator.seedIfNeeded()

        #expect(quoteRepository.seedCallCount == 2)
        #expect(quoteRepository.factoryUseCount == 2)
        #expect(quoteRepository.quoteCountAtSuccessfulSeed == 0)
    }

    @Test
    func purgeExpiredQuotesUsesInjectedRepository() async throws {
        let container = try makeContainer()
        let quoteRepository = DatabaseQuoteRepositorySpy()
        let translationRepository = DatabaseTranslationRepositorySpy()
        let coordinator = DatabaseCoordinator(
            modelContainer: container,
            quoteRepositoryFactory: { _, _ in
                quoteRepository.recordFactoryUse()
                return quoteRepository
            },
            translationRepositoryFactory: { _, _ in translationRepository },
        )

        await coordinator.purgeExpiredQuotes()

        #expect(quoteRepository.purgeCallCount == 1)
        #expect(quoteRepository.lastCutoffDate != nil)
    }

    @Test
    func backfillTranslationsUsesInjectedRepository() async throws {
        let container = try makeContainer()
        let quoteRepository = DatabaseQuoteRepositorySpy()
        let translationRepository = DatabaseTranslationRepositorySpy()
        let coordinator = DatabaseCoordinator(
            modelContainer: container,
            quoteRepositoryFactory: { _, _ in quoteRepository },
            translationRepositoryFactory: { _, _ in translationRepository },
        )

        await coordinator.backfillTranslations()

        #expect(translationRepository.backfillCallCount == 1)
    }

    @Test
    func purgeFailureDiscardsPendingChangesBeforeBackfill() async throws {
        let container = try makeContainer()
        let quoteRepository = DatabaseQuoteRepositorySpy(purgeFails: true)
        let translationRepository = DatabaseTranslationRepositorySpy()
        let coordinator = DatabaseCoordinator(
            modelContainer: container,
            quoteRepositoryFactory: { context, _ in
                quoteRepository.recordFactoryUse(in: context)
                return quoteRepository
            },
            translationRepositoryFactory: { context, _ in
                translationRepository.use(context)
                return translationRepository
            },
        )

        await coordinator.purgeExpiredQuotes()
        await coordinator.backfillTranslations()

        #expect(quoteRepository.purgeCallCount == 1)
        #expect(translationRepository.backfillCallCount == 1)
        #expect(translationRepository.quoteCountAtBackfill == 0)
    }

    @Test
    @MainActor
    func backfillFailurePreservesSavedProgressAndDiscardsPendingChanges() async throws {
        let container = try makeContainer()
        let quoteRepository = DatabaseQuoteRepositorySpy()
        let translationRepository = DatabaseTranslationRepositorySpy(backfillFails: true)
        let coordinator = DatabaseCoordinator(
            modelContainer: container,
            quoteRepositoryFactory: { context, _ in
                quoteRepository.recordFactoryUse(in: context)
                return quoteRepository
            },
            translationRepositoryFactory: { context, _ in
                translationRepository.use(context)
                return translationRepository
            },
        )

        await coordinator.backfillTranslations()
        await coordinator.purgeExpiredQuotes()

        #expect(translationRepository.backfillCallCount == 1)
        #expect(quoteRepository.quoteCountAtSuccessfulPurge == 0)
        let context = ModelContext(container)
        let savedProgress = try #require(context.fetch(FetchDescriptor<TranslationBackfillState>()).first)
        #expect(savedProgress.processedCount == 1)
    }

    @Test
    func maintenanceOperationsShareActorOwnedContext() async throws {
        let container = try makeContainer()
        let contexts = DatabaseContextProbe()
        let quoteRepository = DatabaseQuoteRepositorySpy()
        let translationRepository = DatabaseTranslationRepositorySpy()
        let coordinator = DatabaseCoordinator(
            modelContainer: container,
            quoteRepositoryFactory: { context, _ in
                contexts.record(context)
                return quoteRepository
            },
            translationRepositoryFactory: { context, _ in
                contexts.record(context)
                return translationRepository
            },
        )

        try await coordinator.seedIfNeeded()
        await coordinator.purgeExpiredQuotes()
        await coordinator.backfillTranslations()

        #expect(contexts.identifiers.count == 3)
        #expect(Set(contexts.identifiers).count == 1)
        #expect(quoteRepository.seedCallCount == 1)
        #expect(quoteRepository.purgeCallCount == 1)
        #expect(translationRepository.backfillCallCount == 1)
    }

    @Test
    @MainActor
    func maintenancePersistsSeedAndCompletedTranslationBackfill() async throws {
        let container = try makeContainer()
        let coordinator = DatabaseCoordinator(modelContainer: container)

        try await coordinator.seedIfNeeded()
        await coordinator.backfillTranslations()

        let context = ModelContext(container)
        let quotes = try context.fetch(FetchDescriptor<Quote>())
        let state = try #require(context.fetch(FetchDescriptor<TranslationBackfillState>()).first)
        #expect(!quotes.isEmpty)
        #expect(state.isCompleted)
        #expect(state.processedCount == quotes.count)
        #expect(state.completedAt != nil)
    }

    private func makeContainer() throws -> ModelContainer {
        try TestSupport.makeModelContainer()
    }
}

private final class DatabaseContextProbe: @unchecked Sendable {
    private let lock = NSLock()
    private var recordedIdentifiers: [ObjectIdentifier] = []
    /// Retain contexts to prevent address reuse; the probe never performs storage operations.
    private var retainedContexts: [ModelContext] = []

    var identifiers: [ObjectIdentifier] {
        self.lock.lock()
        defer { self.lock.unlock() }
        return self.recordedIdentifiers
    }

    func record(_ context: ModelContext) {
        self.lock.lock()
        defer { self.lock.unlock() }
        self.retainedContexts.append(context)
        self.recordedIdentifiers.append(ObjectIdentifier(context))
    }
}

private final class DatabaseQuoteRepositorySpy: DatabaseQuoteRepository, @unchecked Sendable {
    private let lock = NSLock()
    private let seedDelay: TimeInterval
    private let purgeFails: Bool
    private var remainingSeedFailures: Int
    private var ownedContext: ModelContext?

    private(set) var seedCallCount = 0
    private(set) var purgeCallCount = 0
    private(set) var factoryUseCount = 0
    private(set) var lastCutoffDate: Date?
    private(set) var quoteCountAtSuccessfulSeed: Int?
    private(set) var quoteCountAtSuccessfulPurge: Int?

    init(seedDelay: TimeInterval = 0, seedFailures: Int = 0, purgeFails: Bool = false) {
        self.seedDelay = seedDelay
        self.remainingSeedFailures = seedFailures
        self.purgeFails = purgeFails
    }

    func recordFactoryUse(in context: ModelContext? = nil) {
        self.lock.lock()
        self.factoryUseCount += 1
        self.ownedContext = context
        self.lock.unlock()
    }

    func seedIfNeeded() throws {
        self.lock.lock()
        self.seedCallCount += 1
        let shouldFail = self.remainingSeedFailures > 0
        if shouldFail {
            self.remainingSeedFailures -= 1
        }
        let context = self.ownedContext
        self.lock.unlock()

        if shouldFail {
            context?.insert(Quote(textLatin: "Uncommitted failed seed", author: "Runatal", collection: .motivation))
            throw DatabaseSeedError.failed
        }
        if let context {
            let count = try context.fetchCount(FetchDescriptor<Quote>())
            self.lock.lock()
            self.quoteCountAtSuccessfulSeed = count
            self.lock.unlock()
        }
        if self.seedDelay > 0 {
            Thread.sleep(forTimeInterval: self.seedDelay)
        }
    }

    func purgeDeletedQuotes(before cutoffDate: Date) throws -> Int {
        self.lock.lock()
        self.purgeCallCount += 1
        self.lastCutoffDate = cutoffDate
        let context = self.ownedContext
        self.lock.unlock()
        if self.purgeFails {
            context?.insert(Quote(textLatin: "Uncommitted failed purge", author: "Runatal", collection: .motivation))
            throw DatabaseMaintenanceError.failed
        }
        if let context {
            let count = try context.fetchCount(FetchDescriptor<Quote>())
            self.lock.lock()
            self.quoteCountAtSuccessfulPurge = count
            self.lock.unlock()
        }
        return 2
    }
}

private enum DatabaseSeedError: Error {
    case failed
}

private enum DatabaseMaintenanceError: Error {
    case failed
}

private final class DatabaseTranslationRepositorySpy: DatabaseTranslationRepository, @unchecked Sendable {
    private let lock = NSLock()
    private let backfillFails: Bool
    private var ownedContext: ModelContext?
    private(set) var backfillCallCount = 0
    private(set) var quoteCountAtBackfill: Int?

    init(backfillFails: Bool = false) {
        self.backfillFails = backfillFails
    }

    func use(_ context: ModelContext) {
        self.lock.lock()
        self.ownedContext = context
        self.lock.unlock()
    }

    func backfillAllQuotes() throws {
        self.lock.lock()
        self.backfillCallCount += 1
        let context = self.ownedContext
        self.lock.unlock()
        guard let context else { return }
        let count = try context.fetchCount(FetchDescriptor<Quote>())
        self.lock.lock()
        self.quoteCountAtBackfill = count
        self.lock.unlock()
        if self.backfillFails {
            context.insert(TranslationBackfillState(processedCount: 1))
            try context.save()
            context.insert(Quote(textLatin: "Uncommitted failed backfill", author: "Runatal", collection: .motivation))
            throw DatabaseMaintenanceError.failed
        }
    }
}
