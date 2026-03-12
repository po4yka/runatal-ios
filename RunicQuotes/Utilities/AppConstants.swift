//
//  AppConstants.swift
//  RunicQuotes
//
//  Created by Claude on 2025-11-15.
//

import Foundation

/// Application-wide constants
enum AppConstants {
    /// Width (in points) of the share-sheet snapshot image.
    static let shareSnapshotWidth: CGFloat = 1000

    /// Seconds per hour, used for widget timeline refresh intervals.
    static let secondsPerHour: TimeInterval = 3600

    /// Seconds per day, used for widget timeline refresh intervals.
    static let secondsPerDay: TimeInterval = 86400

    /// Deterministic daily quote index based on the current date.
    ///
    /// Uses the same calendar arithmetic everywhere (app, repository, widget)
    /// so that the "daily" quote is identical across all surfaces.
    static func dailyQuoteIndex(for date: Date = Date(), totalQuotes count: Int) -> Int {
        guard count > 0 else { return 0 }
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let daysSinceEpoch = calendar.dateComponents(
            [.day],
            from: Date(timeIntervalSince1970: 0),
            to: startOfDay
        ).day ?? 0
        return daysSinceEpoch % count
    }

    /// App Group identifier for shared data between app and widget
    static let appGroupIdentifier = "group.com.po4yka.runicquotes"

    /// Custom URL scheme for deep linking
    static let urlScheme = "runicquotes"

    /// Maximum length for quote text (for performance)
    static let maxQuoteLength = 10_000

    /// Bundle identifier
    static let bundleIdentifier = "com.po4yka.runicquotes"

    /// Subsystem identifier for logging
    static let loggingSubsystem = "com.po4yka.runicquotes"

    /// UserDefaults key tracking whether onboarding has been completed
    static let onboardingCompletedKey = "hasCompletedOnboarding"

    /// UserDefaults key tracking whether the feature tour (coach marks) has been seen
    static let featureTourCompletedKey = "hasCompletedFeatureTour"
}

/// Notification names for app-wide events.
///
/// Used as a lightweight event bus between components that don't share
/// a direct parent-child relationship (deep link handler, quote context
/// menu, tab view).
extension Notification.Name {
    /// Generic tab switch — pass `AppTab` value in userInfo["tab"].
    static let switchToTab = Notification.Name("SwitchToTab")

    /// Legacy: switches to the home (quote) tab.
    static let switchToQuoteTab = Notification.Name("SwitchToQuoteTab")
    /// Legacy: switches to the settings tab.
    static let switchToSettingsTab = Notification.Name("SwitchToSettingsTab")

    static let loadNextQuote = Notification.Name("LoadNextQuote")
    static let preferencesDidChange = Notification.Name("PreferencesDidChange")
    static let quoteTabBarVisibilityChanged = Notification.Name("QuoteTabBarVisibilityChanged")
}
