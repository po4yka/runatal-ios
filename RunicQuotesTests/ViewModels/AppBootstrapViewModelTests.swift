//
//  AppBootstrapViewModelTests.swift
//  RunicQuotes
//
//  Created by Claude on 09.10.26.
//

import Foundation
@testable import RunicQuotes
import Testing

@MainActor
@Suite(.serialized, .tags(.viewModel))
struct AppBootstrapViewModelTests {
    @Test
    func readinessWaitsForSeedingAndPurgeAndRetainsColdLaunchRoute() async {
        let database = BootstrapDatabaseSpy()
        let model = AppBootstrapViewModel(database: database)
        let route = DeepLink.openDailyQuote(script: nil).url
        model.enqueue(route)
        let preparation = Task { await model.prepare() }
        #expect(await waitForBootstrapCondition { await database.didStartSeed })
        #expect(model.phase == .loading)
        #expect(model.consumePendingURLs().isEmpty)
        await database.finishSeeding()
        #expect(await waitForBootstrapCondition { await database.didStartPurge })
        #expect(model.phase == .loading)
        await database.finishPurge()
        await preparation.value
        #expect(model.phase == .ready)
        #expect(model.consumePendingURLs() == [route])
        #expect(model.consumePendingURLs().isEmpty)
    }

    @Test
    func purgeFailureKeepsLibraryUnavailableAndRetryCanFinish() async {
        let database = BootstrapDatabaseSpy()
        await database.configureFailure()
        let model = AppBootstrapViewModel(database: database)
        await model.prepare()
        guard case .failed = model.phase else { Issue.record("Purge failure must block readiness"); return }
        #expect(await database.backfillCount == 0)
        await database.allowImmediateCompletion()
        await model.prepare()
        #expect(model.phase == .ready)
    }
}

private actor BootstrapDatabaseSpy: AppDatabasePreparing {
    var didStartSeed = false
    var didStartPurge = false
    var backfillCount = 0
    private var seedContinuation: CheckedContinuation<Void, Never>?
    private var purgeContinuation: CheckedContinuation<Void, Never>?
    private var immediate = false
    private var failsPurge = false

    func seedIfNeeded() async throws {
        self.didStartSeed = true
        if !self.immediate {
            await withCheckedContinuation { self.seedContinuation = $0 }
        }
    }

    func purgeExpiredQuotes() async throws {
        self.didStartPurge = true
        if self.failsPurge {
            throw CocoaError(.fileWriteUnknown)
        }
        if !self.immediate {
            await withCheckedContinuation { self.purgeContinuation = $0 }
        }
    }

    func backfillTranslations() async {
        self.backfillCount += 1
    }

    func finishSeeding() {
        self.seedContinuation?.resume(); self.seedContinuation = nil
    }

    func finishPurge() {
        self.purgeContinuation?.resume(); self.purgeContinuation = nil
    }

    func configureFailure() {
        self.immediate = true; self.failsPurge = true
    }

    func allowImmediateCompletion() {
        self.immediate = true; self.failsPurge = false
    }
}

private func waitForBootstrapCondition(_ condition: @escaping @Sendable () async -> Bool) async -> Bool {
    let clock = ContinuousClock()
    let deadline = clock.now + .seconds(2)
    while clock.now < deadline {
        if await condition() {
            return true
        }
        try? await Task.sleep(for: .milliseconds(10))
    }
    return await condition()
}
