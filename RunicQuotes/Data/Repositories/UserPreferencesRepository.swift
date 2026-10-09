//
//  UserPreferencesRepository.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import Foundation
import SwiftData

struct UserPreferencesSnapshot {
    var selectedScript: RunicScript = .elder
    var selectedFont: RunicFont = .noto
    var widgetMode: WidgetMode = .daily
    var selectedCollection: QuoteCollection = .all
    var widgetStyle: WidgetStyle = .runeFirst
    var widgetDecorativeGlyphsEnabled = true
    var selectedTheme: AppTheme = .obsidian
    var lastUsedPreset: ReadingPreset?
    var savedQuoteIDs: Set<UUID> = []
    var installedPackIDs: Set<String> = []

    init() {}

    init(from preferences: UserPreferences) {
        self.selectedScript = preferences.selectedScript
        self.selectedFont = preferences.selectedFont
        self.widgetMode = preferences.widgetMode
        self.selectedCollection = preferences.selectedCollection
        self.widgetStyle = preferences.widgetStyle
        self.widgetDecorativeGlyphsEnabled = preferences.widgetDecorativeGlyphsEnabled
        self.selectedTheme = preferences.selectedTheme
        self.lastUsedPreset = preferences.lastUsedPreset
        self.savedQuoteIDs = preferences.savedQuoteIDs
        self.installedPackIDs = preferences.installedPackIDs
    }

    func isQuoteSaved(_ id: UUID) -> Bool {
        self.savedQuoteIDs.contains(id)
    }

    @discardableResult
    mutating func toggleSavedQuote(_ id: UUID) -> Bool {
        if self.savedQuoteIDs.contains(id) {
            self.savedQuoteIDs.remove(id)
            return false
        }

        self.savedQuoteIDs.insert(id)
        return true
    }

    func isPackInstalled(_ id: String) -> Bool {
        self.installedPackIDs.contains(id)
    }

    @discardableResult
    mutating func installPack(_ id: String) -> Bool {
        self.installedPackIDs.insert(id).inserted
    }
}

protocol UserPreferencesRepository: Sendable {
    func snapshot() throws -> UserPreferencesSnapshot
    @discardableResult
    func apply(_ mutations: [UserPreferencesMutation]) throws -> UserPreferencesSnapshot
}

final class SwiftDataUserPreferencesRepository: UserPreferencesRepository, @unchecked Sendable {
    private let modelContainer: ModelContainer

    init(modelContext: ModelContext) {
        self.modelContainer = modelContext.container
    }

    func snapshot() throws -> UserPreferencesSnapshot {
        let context = ModelContext(self.modelContainer)
        context.autosaveEnabled = false
        let preferences = try UserPreferences.getOrCreate(in: context)
        if context.hasChanges {
            try context.save()
        }
        return UserPreferencesSnapshot(from: preferences)
    }

    @discardableResult
    func apply(_ mutations: [UserPreferencesMutation]) throws -> UserPreferencesSnapshot {
        let context = ModelContext(self.modelContainer)
        context.autosaveEnabled = false
        let preferences = try UserPreferences.getOrCreate(in: context)
        var snapshot = UserPreferencesSnapshot(from: preferences)
        for mutation in mutations {
            try mutation.apply(to: &snapshot)
        }
        if preferences.selectedScript != snapshot.selectedScript {
            preferences.selectedScript = snapshot.selectedScript
        }
        if preferences.selectedFont != snapshot.selectedFont {
            preferences.selectedFont = snapshot.selectedFont
        }
        if preferences.widgetMode != snapshot.widgetMode {
            preferences.widgetMode = snapshot.widgetMode
        }
        if preferences.selectedCollection != snapshot.selectedCollection {
            preferences.selectedCollection = snapshot.selectedCollection
        }
        if preferences.widgetStyle != snapshot.widgetStyle {
            preferences.widgetStyle = snapshot.widgetStyle
        }
        if preferences.widgetDecorativeGlyphsEnabled != snapshot.widgetDecorativeGlyphsEnabled {
            preferences.widgetDecorativeGlyphsEnabled = snapshot.widgetDecorativeGlyphsEnabled
        }
        if preferences.selectedTheme != snapshot.selectedTheme {
            preferences.selectedTheme = snapshot.selectedTheme
        }
        if preferences.lastUsedPreset != snapshot.lastUsedPreset {
            preferences.lastUsedPreset = snapshot.lastUsedPreset
        }
        if preferences.savedQuoteIDs != snapshot.savedQuoteIDs {
            preferences.savedQuoteIDs = snapshot.savedQuoteIDs
        }
        if preferences.installedPackIDs != snapshot.installedPackIDs {
            preferences.installedPackIDs = snapshot.installedPackIDs
        }
        try context.save()
        return snapshot
    }
}
