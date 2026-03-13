//
//  UserPreferencesRepository.swift
//  RunicQuotes
//
//  Created by Codex on 2026-03-13.
//

import Foundation
import SwiftData

struct UserPreferencesSnapshot: Sendable {
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

    init() { }

    init(from preferences: UserPreferences) {
        selectedScript = preferences.selectedScript
        selectedFont = preferences.selectedFont
        widgetMode = preferences.widgetMode
        selectedCollection = preferences.selectedCollection
        widgetStyle = preferences.widgetStyle
        widgetDecorativeGlyphsEnabled = preferences.widgetDecorativeGlyphsEnabled
        selectedTheme = preferences.selectedTheme
        lastUsedPreset = preferences.lastUsedPreset
        savedQuoteIDs = preferences.savedQuoteIDs
        installedPackIDs = preferences.installedPackIDs
    }

    func isQuoteSaved(_ id: UUID) -> Bool {
        savedQuoteIDs.contains(id)
    }

    @discardableResult
    mutating func toggleSavedQuote(_ id: UUID) -> Bool {
        if savedQuoteIDs.contains(id) {
            savedQuoteIDs.remove(id)
            return false
        }

        savedQuoteIDs.insert(id)
        return true
    }

    func isPackInstalled(_ id: String) -> Bool {
        installedPackIDs.contains(id)
    }

    @discardableResult
    mutating func installPack(_ id: String) -> Bool {
        installedPackIDs.insert(id).inserted
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
        try UserPreferencesSnapshot(from: UserPreferences.getOrCreate(in: modelContext))
    }

    func save(_ snapshot: UserPreferencesSnapshot) throws {
        let preferences = try UserPreferences.getOrCreate(in: modelContext)
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
        try modelContext.save()
    }
}
