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

    private func makeContainer() throws -> ModelContainer {
        try TestSupport.makeModelContainer()
    }
}

private final class DatabaseQuoteRepositorySpy: DatabaseQuoteRepository, @unchecked Sendable {
    private let lock = NSLock()
    private let seedDelay: TimeInterval

    private(set) var seedCallCount = 0
    private(set) var purgeCallCount = 0
    private(set) var factoryUseCount = 0
    private(set) var lastCutoffDate: Date?

    init(seedDelay: TimeInterval = 0) {
        self.seedDelay = seedDelay
    }

    func recordFactoryUse() {
        self.lock.lock()
        self.factoryUseCount += 1
        self.lock.unlock()
    }

    func seedIfNeeded() throws {
        self.lock.lock()
        self.seedCallCount += 1
        self.lock.unlock()

        if self.seedDelay > 0 {
            Thread.sleep(forTimeInterval: self.seedDelay)
        }
    }

    func purgeDeletedQuotes(before cutoffDate: Date) throws -> Int {
        self.lock.lock()
        self.purgeCallCount += 1
        self.lastCutoffDate = cutoffDate
        self.lock.unlock()
        return 2
    }
}

private final class DatabaseTranslationRepositorySpy: DatabaseTranslationRepository, @unchecked Sendable {
    private let lock = NSLock()
    private(set) var backfillCallCount = 0

    func backfillAllQuotes() throws {
        self.lock.lock()
        self.backfillCallCount += 1
        self.lock.unlock()
    }
}
