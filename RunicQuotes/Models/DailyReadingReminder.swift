//
//  DailyReadingReminder.swift
//  RunicQuotes
//
//  Created by Claude on 09.10.26.
//

import Foundation

struct DailyReminderTime: Codable, Equatable, Sendable {
    let hour: Int
    let minute: Int

    init(hour: Int, minute: Int) throws {
        guard (0 ..< 24).contains(hour), (0 ..< 60).contains(minute) else {
            throw DailyReminderError.invalidTime
        }
        self.hour = hour
        self.minute = minute
    }

    private init(validatedHour: Int, minute: Int) {
        self.hour = validatedHour
        self.minute = minute
    }

    static let morning = DailyReminderTime(validatedHour: 9, minute: 0)

    var date: Date {
        Calendar.current.date(from: DateComponents(hour: self.hour, minute: self.minute)) ?? Date()
    }
}

enum DailyReminderError: LocalizedError {
    case invalidTime
    case permissionDenied
    case reconciliationFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidTime: "Choose a valid reminder time."
        case .permissionDenied: "Allow notifications in system Settings to enable the daily reading reminder."
        case .reconciliationFailed(let detail): "The reminder could not be restored. \(detail)"
        }
    }
}

struct DailyReminderUiState {
    var isEnabled = false
    var time = DailyReminderTime.morning
    var isWorking = false
    var errorMessage: String?
}
