//
//  DailyReminderViewModelTests.swift
//  RunicQuotes
//
//  Created by Claude on 09.10.26.
//

import Foundation
@testable import RunicQuotes
import Testing
import UserNotifications

@MainActor
@Suite(.serialized, .tags(.viewModel))
struct DailyReminderViewModelTests {
    @Test
    func enablingRequiresAcceptedRequestAndPersistedPreference() async throws {
        let context = try TestSupport.makeModelContext()
        let repository = SwiftDataUserPreferencesRepository(modelContext: context)
        let client = ReminderClientSpy()
        let model = DailyReminderViewModel(client: client, preferencesRepository: repository)
        #expect(await model.setEnabled(true))
        #expect(model.state.isEnabled)
        #expect(try repository.snapshot().dailyReminderEnabled)
        #expect(client.scheduledTimes == [.morning])
    }

    @Test
    func permissionDenialDoesNotPersistEnablement() async throws {
        let context = try TestSupport.makeModelContext()
        let repository = SwiftDataUserPreferencesRepository(modelContext: context)
        let client = ReminderClientSpy()
        client.permissionGranted = false
        let model = DailyReminderViewModel(client: client, preferencesRepository: repository)
        #expect(await !model.setEnabled(true))
        #expect(!model.state.isEnabled)
        #expect(try !repository.snapshot().dailyReminderEnabled)
        #expect(client.scheduledTimes.isEmpty)
        #expect(model.state.errorMessage != nil)
    }

    @Test
    func rejectedNativeRequestDoesNotPersistEnablement() async throws {
        let context = try TestSupport.makeModelContext()
        let repository = SwiftDataUserPreferencesRepository(modelContext: context)
        let client = ReminderClientSpy()
        client.schedulingError = TestError.failure
        let model = DailyReminderViewModel(client: client, preferencesRepository: repository)
        #expect(await !model.setEnabled(true))
        #expect(!model.state.isEnabled)
        #expect(try !repository.snapshot().dailyReminderEnabled)
        #expect(model.state.errorMessage != nil)
    }

    @Test
    func failedPersistenceCancelsNewReminder() async {
        let repository = ReminderPreferencesSpy()
        repository.saveError = TestError.failure
        let client = ReminderClientSpy()
        let model = DailyReminderViewModel(client: client, preferencesRepository: repository)
        #expect(await !model.setEnabled(true))
        #expect(!model.state.isEnabled)
        #expect(!repository.value.dailyReminderEnabled)
        #expect(client.scheduledTimes == [.morning])
        #expect(client.cancelCount == 1)
    }

    @Test
    func failedDisablePersistenceRestoresPreviousRequest() async throws {
        let repository = ReminderPreferencesSpy()
        repository.value.dailyReminderEnabled = true
        repository.value.dailyReminderTime = try DailyReminderTime(hour: 17, minute: 45)
        let client = ReminderClientSpy()
        let model = DailyReminderViewModel(client: client, preferencesRepository: repository)
        await model.onAppear()
        repository.saveError = TestError.failure
        #expect(await !model.setEnabled(false))
        #expect(model.state.isEnabled)
        #expect(repository.value.dailyReminderEnabled)
        #expect(client.scheduledTimes == [repository.value.dailyReminderTime, repository.value.dailyReminderTime])
        #expect(client.cancelCount == 1)
    }

    @Test
    func disabledStartupAllowsMainActorProgressWhileCancellationIsPending() async {
        let repository = ReminderPreferencesSpy()
        let client = SuspendedReminderClient()
        let model = DailyReminderViewModel(client: client, preferencesRepository: repository)
        let startup = Task { await model.onAppear() }

        await client.waitForCancellation()
        // Reading UI state here requires the MainActor while the service is still pending.
        #expect(model.state.isWorking)
        #expect(!model.state.isEnabled)
        #expect(!repository.value.dailyReminderEnabled)
        #expect(await !model.setEnabled(true))

        await client.finishCancellation()
        await startup.value
        #expect(!model.state.isWorking)
        #expect(model.state.errorMessage == nil)
    }

    @Test
    func disablingAwaitsCancellationBeforePersistingPreference() async {
        let repository = ReminderPreferencesSpy()
        repository.value.dailyReminderEnabled = true
        let client = SuspendedReminderClient()
        let model = DailyReminderViewModel(client: client, preferencesRepository: repository)
        await model.onAppear()
        let disable = Task { await model.setEnabled(false) }

        await client.waitForCancellation()
        #expect(model.state.isWorking)
        #expect(model.state.isEnabled)
        #expect(repository.value.dailyReminderEnabled)

        await client.finishCancellation()
        #expect(await disable.value)
        #expect(!model.state.isWorking)
        #expect(!model.state.isEnabled)
        #expect(!repository.value.dailyReminderEnabled)
    }

    @Test
    func failedDisablePersistenceWaitsForCancellationBeforeRestoringRequest() async {
        let repository = ReminderPreferencesSpy()
        repository.value.dailyReminderEnabled = true
        let client = SuspendedReminderClient()
        let model = DailyReminderViewModel(client: client, preferencesRepository: repository)
        await model.onAppear()
        repository.saveError = TestError.failure
        let disable = Task { await model.setEnabled(false) }

        await client.waitForCancellation()
        #expect(await client.scheduledTimes == [.morning])
        #expect(model.state.errorMessage == nil)

        await client.finishCancellation()
        #expect(await !disable.value)
        #expect(await client.scheduledTimes == [.morning, .morning])
        #expect(model.state.isEnabled)
        #expect(repository.value.dailyReminderEnabled)
        #expect(model.state.errorMessage != nil)
    }

    @Test
    func nativeRequestUsesOwnedIdentifierLocalHourAndHonestReminderContent() throws {
        let time = try DailyReminderTime(hour: 17, minute: 45)
        let request = SystemDailyReminderClient.request(at: time)
        #expect(request.identifier == SystemDailyReminderClient.requestIdentifier)
        let trigger = try #require(request.trigger as? UNCalendarNotificationTrigger)
        #expect(trigger.repeats)
        #expect(trigger.dateComponents.hour == 17)
        #expect(trigger.dateComponents.minute == 45)
        #expect(request.content.title == "Daily reading reminder")
        #expect(request.content.body == "Open today’s passage in Runatal.")
        #expect(request.content.userInfo["route"] as? String == "daily")
    }

    private enum TestError: Error { case failure }
}

@MainActor
private final class ReminderClientSpy: DailyReminderClient {
    var permissionGranted = true
    var authorized = true
    var schedulingError: (any Error)?
    var scheduledTimes: [DailyReminderTime] = []
    var cancelCount = 0

    func requestPermission() async throws -> Bool {
        self.permissionGranted
    }

    func isAuthorized() async -> Bool {
        self.authorized
    }

    func schedule(at time: DailyReminderTime) async throws {
        if let error = self.schedulingError {
            throw error
        }
        self.scheduledTimes.append(time)
    }

    func cancel() async {
        self.cancelCount += 1
    }
}

private final class ReminderPreferencesSpy: UserPreferencesRepository, @unchecked Sendable {
    var value = UserPreferencesSnapshot()
    var saveError: (any Error)?
    func snapshot() throws -> UserPreferencesSnapshot {
        self.value
    }

    func apply(_ mutations: [UserPreferencesMutation]) throws -> UserPreferencesSnapshot {
        if let error = self.saveError {
            throw error
        }
        var updated = self.value
        for mutation in mutations {
            try mutation.apply(to: &updated)
        }
        self.value = updated
        return updated
    }
}

private actor SuspendedReminderClient: DailyReminderClient {
    private(set) var scheduledTimes: [DailyReminderTime] = []
    private var cancellationStarted = false
    private var cancellationContinuation: CheckedContinuation<Void, Never>?
    private var startContinuation: CheckedContinuation<Void, Never>?

    func requestPermission() async throws -> Bool {
        true
    }

    func isAuthorized() async -> Bool {
        true
    }

    func schedule(at time: DailyReminderTime) async throws {
        self.scheduledTimes.append(time)
    }

    func cancel() async {
        self.cancellationStarted = true
        self.startContinuation?.resume()
        self.startContinuation = nil
        await withCheckedContinuation { self.cancellationContinuation = $0 }
    }

    func waitForCancellation() async {
        guard !self.cancellationStarted else { return }
        await withCheckedContinuation { self.startContinuation = $0 }
    }

    func finishCancellation() {
        self.cancellationContinuation?.resume()
        self.cancellationContinuation = nil
    }
}
