//
//  UserPreferences.swift
//  RunicQuotes
//
//  Created by Claude on 30.09.25.
//

import Foundation
import SwiftData

/// Stores user preferences and settings
@Model
final class UserPreferences {
    /// Unique identifier (singleton pattern)
    @Attribute(.unique) var id: UUID

    @Attribute(.unique) var singletonKey: String?

    /// Nil marks a legacy library that predates durable catalog import receipts.
    var catalogIdentityVersion: String?

    /// Currently selected runic script
    var selectedScriptRaw: String

    /// Currently selected font
    var selectedFontRaw: String

    /// Widget display mode
    var widgetModeRaw: String

    /// Selected quote collection
    var selectedCollectionRaw: String?

    /// Widget visual style raw value
    var widgetStyleRaw: String?

    /// Whether decorative glyph identity elements are enabled in widgets
    var widgetDecorativeGlyphsEnabledRaw: Bool?

    /// Selected visual theme
    var selectedThemeRaw: String

    /// Last user-selected recommended preset
    var lastUsedPresetRaw: String?

    /// Comma-separated list of saved quote UUID strings.
    /// Uses a serialized string rather than `[String]` to avoid a schema migration
    /// that would lose existing saved-quote data on update.
    var savedQuoteIDsRaw: String?

    /// Comma-separated list of installed quote pack IDs.
    var installedPackIDsRaw: String?

    var dailyReminderEnabledRaw: Bool?
    var dailyReminderHourRaw: Int?
    var dailyReminderMinuteRaw: Int?

    var dailyReminderEnabled: Bool {
        get { self.dailyReminderEnabledRaw ?? false }
        set { self.dailyReminderEnabledRaw = newValue; self.lastUpdated = Date() }
    }

    var dailyReminderTime: DailyReminderTime {
        get { (try? DailyReminderTime(hour: self.dailyReminderHourRaw ?? 9, minute: self.dailyReminderMinuteRaw ?? 0)) ?? .morning }
        set {
            self.dailyReminderHourRaw = newValue.hour
            self.dailyReminderMinuteRaw = newValue.minute
            self.lastUpdated = Date()
        }
    }

    /// Last updated timestamp
    var lastUpdated: Date

    /// Computed property for script
    var selectedScript: RunicScript {
        get {
            RunicScript(rawValue: self.selectedScriptRaw) ?? .elder
        }
        set {
            self.selectedScriptRaw = newValue.rawValue
            self.lastUpdated = Date()
        }
    }

    /// Computed property for font
    var selectedFont: RunicFont {
        get {
            RunicFont(rawValue: self.selectedFontRaw) ?? .noto
        }
        set {
            self.selectedFontRaw = newValue.rawValue
            self.lastUpdated = Date()
        }
    }

    /// Computed property for widget mode
    var widgetMode: WidgetMode {
        get {
            WidgetMode(rawValue: self.widgetModeRaw) ?? .daily
        }
        set {
            self.widgetModeRaw = newValue.rawValue
            self.lastUpdated = Date()
        }
    }

    /// Computed property for quote collection
    var selectedCollection: QuoteCollection {
        get {
            QuoteCollection(rawValue: self.selectedCollectionRaw ?? "") ?? .all
        }
        set {
            self.selectedCollectionRaw = newValue.rawValue
            self.lastUpdated = Date()
        }
    }

    /// Computed property for widget visual style
    var widgetStyle: WidgetStyle {
        get {
            WidgetStyle(rawValue: self.widgetStyleRaw ?? "") ?? .runeFirst
        }
        set {
            self.widgetStyleRaw = newValue.rawValue
            self.lastUpdated = Date()
        }
    }

    /// Whether decorative glyph identity elements are enabled in widgets.
    var widgetDecorativeGlyphsEnabled: Bool {
        get {
            self.widgetDecorativeGlyphsEnabledRaw ?? true
        }
        set {
            self.widgetDecorativeGlyphsEnabledRaw = newValue
            self.lastUpdated = Date()
        }
    }

    /// Computed property for visual theme
    var selectedTheme: AppTheme {
        get {
            AppTheme(rawValue: self.selectedThemeRaw) ?? .obsidian
        }
        set {
            self.selectedThemeRaw = newValue.rawValue
            self.lastUpdated = Date()
        }
    }

    /// Last user-selected recommended preset.
    var lastUsedPreset: ReadingPreset? {
        get {
            guard let lastUsedPresetRaw, !lastUsedPresetRaw.isEmpty else {
                return nil
            }
            return ReadingPreset(rawValue: lastUsedPresetRaw)
        }
        set {
            self.lastUsedPresetRaw = newValue?.rawValue
            self.lastUpdated = Date()
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
            self.savedQuoteIDsRaw = newValue
                .map(\.uuidString)
                .sorted()
                .joined(separator: ",")
            self.lastUpdated = Date()
        }
    }

    /// Initialize with default preferences
    init(
        selectedScript: RunicScript = .elder,
        selectedFont: RunicFont = .noto,
        widgetMode: WidgetMode = .daily,
        selectedCollection: QuoteCollection = .all,
        widgetStyle: WidgetStyle = .runeFirst,
        widgetDecorativeGlyphsEnabled: Bool = true,
        selectedTheme: AppTheme = .obsidian,
        lastUsedPreset: ReadingPreset? = nil,
        savedQuoteIDs: Set<UUID> = [],
    ) {
        self.id = UUID(uuid: (0x52, 0x75, 0x6E, 0x61, 0x74, 0x61, 0x6C, 0, 0, 0, 0, 0, 0, 0, 0, 1))
        self.singletonKey = "user-preferences"
        self.catalogIdentityVersion = "v1"
        self.selectedScriptRaw = selectedScript.rawValue
        self.selectedFontRaw = selectedFont.rawValue
        self.widgetModeRaw = widgetMode.rawValue
        self.selectedCollectionRaw = selectedCollection.rawValue
        self.widgetStyleRaw = widgetStyle.rawValue
        self.widgetDecorativeGlyphsEnabledRaw = widgetDecorativeGlyphsEnabled
        self.selectedThemeRaw = selectedTheme.rawValue
        self.lastUsedPresetRaw = lastUsedPreset?.rawValue
        self.savedQuoteIDsRaw = savedQuoteIDs
            .map(\.uuidString)
            .sorted()
            .joined(separator: ",")
        self.lastUpdated = Date()
    }

    /// Check whether a quote is saved.
    func isQuoteSaved(_ id: UUID) -> Bool {
        self.savedQuoteIDs.contains(id)
    }

    /// Toggle the saved state for a quote and return the resulting state.
    @discardableResult
    func toggleSavedQuote(_ id: UUID) -> Bool {
        var ids = self.savedQuoteIDs
        let isNowSaved: Bool

        if ids.contains(id) {
            ids.remove(id)
            isNowSaved = false
        } else {
            ids.insert(id)
            isNowSaved = true
        }

        self.savedQuoteIDs = ids
        return isNowSaved
    }

    /// Installed quote pack identifiers.
    var installedPackIDs: Set<String> {
        get {
            guard let installedPackIDsRaw, !installedPackIDsRaw.isEmpty else {
                return []
            }
            return Set(installedPackIDsRaw.split(separator: ",").map(String.init))
        }
        set {
            self.installedPackIDsRaw = newValue.sorted().joined(separator: ",")
            self.lastUpdated = Date()
        }
    }

    /// Whether a given pack is installed.
    func isPackInstalled(_ packID: String) -> Bool {
        self.installedPackIDs.contains(packID)
    }

    /// Get or create the singleton preferences instance
    /// - Parameter context: The model context to use
    /// - Returns: The user preferences instance
    static func getOrCreate(in context: ModelContext) throws -> UserPreferences {
        let existing = try context.fetch(FetchDescriptor<UserPreferences>()).sorted {
            if $0.lastUpdated != $1.lastUpdated {
                return $0.lastUpdated > $1.lastUpdated
            }
            return $0.id.uuidString < $1.id.uuidString
        }

        if let first = existing.first {
            // Keep the newest appearance settings and union library membership from duplicate legacy rows.
            if existing.count > 1 {
                first.savedQuoteIDs = existing.reduce(into: Set<UUID>()) { $0.formUnion($1.savedQuoteIDs) }
                first.installedPackIDs = existing.reduce(into: Set<String>()) { $0.formUnion($1.installedPackIDs) }
                for duplicate in existing.dropFirst() {
                    context.delete(duplicate)
                }
            }
            if first.singletonKey != "user-preferences" {
                first.singletonKey = "user-preferences"
            }
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
            selectedTheme: .obsidian,
        )
    }
}
