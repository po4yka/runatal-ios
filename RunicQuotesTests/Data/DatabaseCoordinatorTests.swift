//
//  DatabaseCoordinatorTests.swift
//  RunicQuotesTests
//
//  Created by Codex on 2026-03-13.
//

import Foundation
import SwiftData
import XCTest
@testable import RunicQuotes

final class DatabaseCoordinatorTests: XCTestCase {
    func testSeedIfNeededCoalescesConcurrentRequests() async throws {
        let container = try makeContainer()
        let quoteRepository = DatabaseQuoteRepositorySpy(seedDelay: 0.05)
        let translationRepository = DatabaseTranslationRepositorySpy()
        let coordinator = DatabaseCoordinator(
            modelContainer: container,
            quoteRepositoryFactory: { _, _ in
                quoteRepository.recordFactoryUse()
                return quoteRepository
            },
            translationRepositoryFactory: { _, _ in translationRepository }
        )

        async let firstSeed: Void = coordinator.seedIfNeeded()
        async let secondSeed: Void = coordinator.seedIfNeeded()
        _ = try await (firstSeed, secondSeed)

        XCTAssertEqual(quoteRepository.seedCallCount, 1)
        XCTAssertEqual(quoteRepository.factoryUseCount, 1)
    }

    func testPurgeExpiredQuotesUsesInjectedRepository() async throws {
        let container = try makeContainer()
        let quoteRepository = DatabaseQuoteRepositorySpy()
        let translationRepository = DatabaseTranslationRepositorySpy()
        let coordinator = DatabaseCoordinator(
            modelContainer: container,
            quoteRepositoryFactory: { _, _ in
                quoteRepository.recordFactoryUse()
                return quoteRepository
            },
            translationRepositoryFactory: { _, _ in translationRepository }
        )

        await coordinator.purgeExpiredQuotes()

        XCTAssertEqual(quoteRepository.purgeCallCount, 1)
        XCTAssertNotNil(quoteRepository.lastCutoffDate)
    }

    func testBackfillTranslationsUsesInjectedRepository() async throws {
        let container = try makeContainer()
        let quoteRepository = DatabaseQuoteRepositorySpy()
        let translationRepository = DatabaseTranslationRepositorySpy()
        let coordinator = DatabaseCoordinator(
            modelContainer: container,
            quoteRepositoryFactory: { _, _ in quoteRepository },
            translationRepositoryFactory: { _, _ in translationRepository }
        )

        await coordinator.backfillTranslations()

        XCTAssertEqual(translationRepository.backfillCallCount, 1)
    }

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([Quote.self, UserPreferences.self, TranslationRecord.self, TranslationBackfillState.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: config)
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
        lock.lock()
        factoryUseCount += 1
        lock.unlock()
    }

    func seedIfNeeded() throws {
        lock.lock()
        seedCallCount += 1
        lock.unlock()
        if seedDelay > 0 {
            Thread.sleep(forTimeInterval: seedDelay)
        }
    }

    func purgeDeletedQuotes(before cutoffDate: Date) throws -> Int {
        lock.lock()
        purgeCallCount += 1
        lastCutoffDate = cutoffDate
        lock.unlock()
        return 2
    }
}

private final class DatabaseTranslationRepositorySpy: DatabaseTranslationRepository, @unchecked Sendable {
    private let lock = NSLock()
    private(set) var backfillCallCount = 0

    func backfillAllQuotes() throws {
        lock.lock()
        backfillCallCount += 1
        lock.unlock()
    }
}
