//
//  UserPreferences.swift
//  RunicQuotes
//
//  Created by Claude on 2025-11-15.
//

import Foundation
import SwiftData

/// Stores user preferences and settings
@Model
final class UserPreferences {
    /// Unique identifier (singleton pattern)
    @Attribute(.unique) var id: UUID

    /// Currently selected runic script
    var selectedScriptRaw: String

    /// Currently selected font
    var selectedFontRaw: String

    /// Widget display mode
    var widgetModeRaw: String

    /// Selected visual theme
    var selectedThemeRaw: String

    /// Comma-separated list of saved quote UUID strings
    var savedQuoteIDsRaw: String?

    /// Last updated timestamp
    var lastUpdated: Date

    /// Computed property for script
    var selectedScript: RunicScript {
        get {
            RunicScript(rawValue: selectedScriptRaw) ?? .elder
        }
        set {
            selectedScriptRaw = newValue.rawValue
            lastUpdated = Date()
        }
    }

    /// Computed property for font
    var selectedFont: RunicFont {
        get {
            RunicFont(rawValue: selectedFontRaw) ?? .noto
        }
        set {
            selectedFontRaw = newValue.rawValue
            lastUpdated = Date()
        }
    }

    /// Computed property for widget mode
    var widgetMode: WidgetMode {
        get {
            WidgetMode(rawValue: widgetModeRaw) ?? .daily
        }
        set {
            widgetModeRaw = newValue.rawValue
            lastUpdated = Date()
        }
    }

    /// Computed property for visual theme
    var selectedTheme: AppTheme {
        get {
            AppTheme(rawValue: selectedThemeRaw) ?? .obsidian
        }
        set {
            selectedThemeRaw = newValue.rawValue
            lastUpdated = Date()
        }
    }

    /// Saved quote identifiers
    var savedQuoteIDs: Set<UUID> {
        get {
            guard let savedQuoteIDsRaw, !savedQuoteIDsRaw.isEmpty else {
                return []
            }

            let parsed = savedQuoteIDsRaw
                .split(separator: ",")
                .compactMap { UUID(uuidString: String($0)) }

            return Set(parsed)
        }
        set {
            savedQuoteIDsRaw = newValue
                .map(\.uuidString)
                .sorted()
                .joined(separator: ",")
            lastUpdated = Date()
        }
    }

    /// Initialize with default preferences
    init(
        selectedScript: RunicScript = .elder,
        selectedFont: RunicFont = .noto,
        widgetMode: WidgetMode = .daily,
        selectedTheme: AppTheme = .obsidian,
        savedQuoteIDs: Set<UUID> = []
    ) {
        self.id = UUID()
        self.selectedScriptRaw = selectedScript.rawValue
        self.selectedFontRaw = selectedFont.rawValue
        self.widgetModeRaw = widgetMode.rawValue
        self.selectedThemeRaw = selectedTheme.rawValue
        self.savedQuoteIDsRaw = savedQuoteIDs
            .map(\.uuidString)
            .sorted()
            .joined(separator: ",")
        self.lastUpdated = Date()
    }

    /// Check whether a quote is saved.
    func isQuoteSaved(_ id: UUID) -> Bool {
        savedQuoteIDs.contains(id)
    }

    /// Toggle the saved state for a quote and return the resulting state.
    @discardableResult
    func toggleSavedQuote(_ id: UUID) -> Bool {
        var ids = savedQuoteIDs
        let isNowSaved: Bool

        if ids.contains(id) {
            ids.remove(id)
            isNowSaved = false
        } else {
            ids.insert(id)
            isNowSaved = true
        }

        savedQuoteIDs = ids
        return isNowSaved
    }

    /// Get or create the singleton preferences instance
    /// - Parameter context: The model context to use
    /// - Returns: The user preferences instance
    static func getOrCreate(in context: ModelContext) throws -> UserPreferences {
        let descriptor = FetchDescriptor<UserPreferences>()
        let existing = try context.fetch(descriptor)

        if let first = existing.first {
            return first
        }

        // Create new preferences
        let preferences = UserPreferences()
        context.insert(preferences)
        return preferences
    }
}

/// Extension for preview and testing
extension UserPreferences {
    /// Sample preferences for previews
    static var sample: UserPreferences {
        UserPreferences(
            selectedScript: .elder,
            selectedFont: .noto,
            widgetMode: .daily,
            selectedTheme: .obsidian
        )
    }
}
