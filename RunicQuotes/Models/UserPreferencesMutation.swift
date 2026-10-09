//
//  UserPreferencesMutation.swift
//  RunicQuotes
//
//  Created by Claude on 09.10.26.
//

import Foundation

/// A user action applied to current persisted preferences, never to a caller's stale snapshot.
enum UserPreferencesMutation: Sendable {
    case script(RunicScript)
    case font(RunicFont)
    case widgetMode(WidgetMode)
    case collection(QuoteCollection)
    case widgetStyle(WidgetStyle)
    case decorativeGlyphs(Bool)
    case theme(AppTheme)
    case preset(ReadingPreset)
    case toggleSavedQuote(UUID)
    case removeSavedQuote(UUID)
    case installPack(String)
    case resetReadingSettings

    func apply(to preferences: inout UserPreferencesSnapshot) throws {
        switch self {
        case .script(let script):
            preferences.selectedScript = script
            if !preferences.selectedFont.isCompatible(with: script) {
                preferences.selectedFont = RunicFontConfiguration.recommendedFont(for: script)
            }
        case .font(let font):
            guard font.isCompatible(with: preferences.selectedScript) else {
                throw UserPreferencesMutationError.incompatibleFont
            }
            preferences.selectedFont = font
        case .widgetMode(let mode):
            preferences.widgetMode = mode
        case .collection(let collection):
            preferences.selectedCollection = collection
        case .widgetStyle(let style):
            preferences.widgetStyle = style
        case .decorativeGlyphs(let enabled):
            preferences.widgetDecorativeGlyphsEnabled = enabled
        case .theme(let theme):
            preferences.selectedTheme = theme
        case .preset(let preset):
            preferences.selectedScript = preset.script
            preferences.selectedFont = preset.font
            preferences.lastUsedPreset = preset
        case .toggleSavedQuote(let id):
            preferences.toggleSavedQuote(id)
        case .removeSavedQuote(let id):
            preferences.savedQuoteIDs.remove(id)
        case .installPack(let id):
            preferences.installPack(id)
        case .resetReadingSettings:
            preferences.selectedScript = .elder
            preferences.selectedFont = .noto
            preferences.widgetMode = .daily
            preferences.widgetStyle = .runeFirst
            preferences.widgetDecorativeGlyphsEnabled = true
            preferences.selectedTheme = .obsidian
        }
    }
}

enum UserPreferencesMutationError: LocalizedError {
    case incompatibleFont

    var errorDescription: String? {
        "The selected font does not support the current script."
    }
}
