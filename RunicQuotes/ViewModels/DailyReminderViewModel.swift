//
//  DailyReminderViewModel.swift
//  RunicQuotes
//
//  Created by Claude on 09.10.26.
//

import Combine
import Foundation

@MainActor
final class DailyReminderViewModel: ObservableObject {
    @Published private(set) var state = DailyReminderUiState()
    private let client: any DailyReminderClient
    private let preferencesRepository: any UserPreferencesRepository

    init(client: any DailyReminderClient, preferencesRepository: any UserPreferencesRepository) {
        self.client = client
        self.preferencesRepository = preferencesRepository
    }

    func onAppear() async {
        guard !self.state.isWorking else { return }
        self.state.isWorking = true
        defer { self.state.isWorking = false }
        self.state.errorMessage = nil
        do {
            let preferences = try self.preferencesRepository.snapshot()
            self.state.time = preferences.dailyReminderTime
            self.state.isEnabled = false
            guard preferences.dailyReminderEnabled else { await self.client.cancel(); return }
            guard await self.client.isAuthorized() else {
                await self.client.cancel()
                throw DailyReminderError.permissionDenied
            }
            try await self.client.schedule(at: preferences.dailyReminderTime)
            self.state.isEnabled = true
        } catch {
            self.state.errorMessage = error.localizedDescription
        }
    }

    @discardableResult
    func setEnabled(_ enabled: Bool) async -> Bool {
        await self.update(enabled: enabled, time: self.state.time)
    }

    @discardableResult
    func setTime(_ date: Date) async -> Bool {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        do {
            let time = try DailyReminderTime(hour: components.hour ?? -1, minute: components.minute ?? -1)
            return await self.update(enabled: self.state.isEnabled, time: time)
        } catch {
            self.state.errorMessage = error.localizedDescription
            return false
        }
    }

    private func update(enabled: Bool, time: DailyReminderTime) async -> Bool {
        guard !self.state.isWorking else { return false }
        self.state.isWorking = true
        self.state.errorMessage = nil
        defer { self.state.isWorking = false }
        do {
            // Capture persisted state rather than a potentially stale screen snapshot.
            let previous = try self.preferencesRepository.snapshot()
            if enabled {
                guard try await self.client.requestPermission(), await self.client.isAuthorized() else {
                    await self.client.cancel()
                    self.state.isEnabled = false
                    throw DailyReminderError.permissionDenied
                }
                try await self.client.schedule(at: time)
            } else {
                await self.client.cancel()
            }
            do {
                let saved = try self.preferencesRepository.apply([.dailyReminder(enabled: enabled, time: time)])
                self.state.time = saved.dailyReminderTime
                self.state.isEnabled = saved.dailyReminderEnabled
                return true
            } catch {
                let persistenceError = error
                do {
                    if previous.dailyReminderEnabled, await self.client.isAuthorized() {
                        try await self.client.schedule(at: previous.dailyReminderTime)
                        self.state.isEnabled = true
                    } else {
                        await self.client.cancel()
                        self.state.isEnabled = false
                    }
                    self.state.time = previous.dailyReminderTime
                } catch {
                    self.state.isEnabled = false
                    await self.client.cancel()
                    throw DailyReminderError.reconciliationFailed("\(persistenceError.localizedDescription) \(error.localizedDescription)")
                }
                throw persistenceError
            }
        } catch {
            self.state.errorMessage = error.localizedDescription
            return false
        }
    }
}

private struct PreviewDailyReminderClient: DailyReminderClient {
    func requestPermission() async throws -> Bool {
        true
    }

    func isAuthorized() async -> Bool {
        true
    }

    func schedule(at time: DailyReminderTime) async throws {}
    func cancel() async {}
}

extension DailyReminderViewModel {
    static func preview() -> DailyReminderViewModel {
        DailyReminderViewModel(client: PreviewDailyReminderClient(), preferencesRepository: PreviewUserPreferencesRepository.shared)
    }
}
