//
//  AppConstants.swift
//  RunicQuotes
//
//  Created by Claude on 2025-11-15.
//

import Foundation

/// Application-wide constants
enum AppConstants {
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
}

/// Notification names for app-wide events
extension Notification.Name {
    static let switchToQuoteTab = Notification.Name("SwitchToQuoteTab")
    static let switchToSettingsTab = Notification.Name("SwitchToSettingsTab")
    static let loadNextQuote = Notification.Name("LoadNextQuote")
    static let preferencesDidChange = Notification.Name("PreferencesDidChange")
    static let quoteTabBarVisibilityChanged = Notification.Name("QuoteTabBarVisibilityChanged")
}
