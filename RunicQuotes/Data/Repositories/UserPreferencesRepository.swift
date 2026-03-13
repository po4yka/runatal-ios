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
    func save(_ snapshot: UserPreferencesSnapshot) throws
}

final class SwiftDataUserPreferencesRepository: UserPreferencesRepository, @unchecked Sendable {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func snapshot() throws -> UserPreferencesSnapshot {
        try UserPreferencesSnapshot(from: UserPreferences.getOrCreate(in: self.modelContext))
    }

    func save(_ snapshot: UserPreferencesSnapshot) throws {
        let preferences = try UserPreferences.getOrCreate(in: self.modelContext)
        preferences.selectedScript = snapshot.selectedScript
        preferences.selectedFont = snapshot.selectedFont
        preferences.widgetMode = snapshot.widgetMode
        preferences.selectedCollection = snapshot.selectedCollection
        preferences.widgetStyle = snapshot.widgetStyle
        preferences.widgetDecorativeGlyphsEnabled = snapshot.widgetDecorativeGlyphsEnabled
        preferences.selectedTheme = snapshot.selectedTheme
        preferences.lastUsedPreset = snapshot.lastUsedPreset
        preferences.savedQuoteIDs = snapshot.savedQuoteIDs
        preferences.installedPackIDs = snapshot.installedPackIDs
        try self.modelContext.save()
    }
}
