//
//  DailyReminderClient.swift
//  RunicQuotes
//
//  Created by Claude on 09.10.26.
//

import Foundation
import UserNotifications

@MainActor
protocol DailyReminderClient {
    func requestPermission() async throws -> Bool
    func isAuthorized() async -> Bool
    func schedule(at time: DailyReminderTime) async throws
    func cancel()
}

@MainActor
final class SystemDailyReminderClient: DailyReminderClient {
    nonisolated static let requestIdentifier = "runatal.daily-reading-reminder"
    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func requestPermission() async throws -> Bool {
        try await self.center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    func isAuthorized() async -> Bool {
        let settings = await self.center.notificationSettings()
        return settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
    }

    static func request(at time: DailyReminderTime) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = "Daily reading reminder"
        content.body = "Open today’s passage in Runatal."
        content.sound = .default
        content.userInfo = ["route": "daily"]
        var components = DateComponents()
        components.calendar = .current
        components.hour = time.hour
        components.minute = time.minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        return UNNotificationRequest(identifier: self.requestIdentifier, content: content, trigger: trigger)
    }

    func schedule(at time: DailyReminderTime) async throws {
        try await self.center.add(Self.request(at: time))
    }

    func cancel() {
        self.center.removePendingNotificationRequests(withIdentifiers: [Self.requestIdentifier])
    }
}

final class DailyReminderNotificationDelegate: NSObject, UNUserNotificationCenterDelegate, @unchecked Sendable {
    private let openDaily: @MainActor @Sendable () -> Void

    init(openDaily: @escaping @MainActor @Sendable () -> Void) {
        self.openDaily = openDaily
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void,
    ) {
        let isOwnedReminder = response.actionIdentifier == UNNotificationDefaultActionIdentifier
            && response.notification.request.identifier == SystemDailyReminderClient.requestIdentifier
            && response.notification.request.content.userInfo["route"] as? String == "daily"
        completionHandler()
        guard isOwnedReminder else { return }
        Task { @MainActor in self.openDaily() }
    }
}
