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

    /// Initialize with default preferences
    init(
        selectedScript: RunicScript = .elder,
        selectedFont: RunicFont = .noto,
        widgetMode: WidgetMode = .daily
    ) {
        self.id = UUID()
        self.selectedScriptRaw = selectedScript.rawValue
        self.selectedFontRaw = selectedFont.rawValue
        self.widgetModeRaw = widgetMode.rawValue
        self.lastUpdated = Date()
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
            widgetMode: .daily
        )
    }
}
