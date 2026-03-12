//
//  SettingsViewModel.swift
//  RunicQuotes
//
//  Created by Claude on 2025-11-15.
//

import Foundation
import SwiftUI
import SwiftData

/// ViewModel for the settings screen
@MainActor
final class SettingsViewModel: ObservableObject {
    // MARK: - State

    struct State: Sendable {
        var selectedScript: RunicScript = .elder
        var selectedFont: RunicFont = .noto
        var widgetMode: WidgetMode = .daily
        var widgetStyle: WidgetStyle = .runeFirst
        var widgetDecorativeGlyphsEnabled: Bool = true
        var selectedTheme: AppTheme = .obsidian
        var lastUsedPreset: ReadingPreset?
        var errorMessage: String?
        var isLoading: Bool = false
    }

    @Published private(set) var state = State()

    // MARK: - Dependencies

    private var modelContext: ModelContext
    private var preferences: UserPreferences?
    private var isConfiguredWithEnvironmentContext = false

    // MARK: - Computed Properties

    /// Get available fonts for the current script
    var availableFonts: [RunicFont] {
        RunicFont.allCases.filter { font in
            font.isCompatible(with: state.selectedScript)
        }
    }

    /// Get the current font name for display
    var currentFontName: String {
        RunicFontConfiguration.fontName(for: state.selectedScript, font: state.selectedFont)
    }

    /// Curated presets for quick setup.
    var recommendedPresets: [ReadingPreset] {
        ReadingPreset.allCases
    }

    /// Static text used for the live preview panel.
    var livePreviewLatinText: String {
        "The old paths still whisper."
    }

    /// Runic transliteration for the live preview panel.
    var livePreviewRunicText: String {
        RunicTransliterator.transliterate(livePreviewLatinText, to: state.selectedScript)
    }

    /// Whether reset action should be active.
    var isAtDefaults: Bool {
        state.selectedScript == .elder &&
        state.selectedFont == .noto &&
        state.widgetMode == .daily &&
        state.widgetStyle == .runeFirst &&
        state.widgetDecorativeGlyphsEnabled &&
        state.selectedTheme == .obsidian
    }

    /// Whether last preset restore action can run.
    var canRestoreLastPreset: Bool {
        state.lastUsedPreset != nil
    }

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Public API

    /// Load preferences when view appears
    func onAppear() {
        Task {
            await loadPreferences()
        }
    }

    /// Rebind dependencies to the environment-provided context once the view is mounted.
    func configureIfNeeded(modelContext: ModelContext) {
        guard !isConfiguredWithEnvironmentContext else { return }
        self.modelContext = modelContext
        isConfiguredWithEnvironmentContext = true
    }

    /// Update the selected script
    func updateScript(_ script: RunicScript) {
        state.selectedScript = script

        // Ensure font compatibility
        if !state.selectedFont.isCompatible(with: script) {
            state.selectedFont = RunicFontConfiguration.recommendedFont(for: script)
        }

        savePreferences()
    }

    /// Update the selected font
    func updateFont(_ font: RunicFont) {
        guard font.isCompatible(with: state.selectedScript) else {
            state.errorMessage = "\(font.displayName) is not compatible with \(state.selectedScript.displayName)"
            return
        }

        state.selectedFont = font
        savePreferences()
    }

    /// Update widget mode
    func updateWidgetMode(_ mode: WidgetMode) {
        state.widgetMode = mode
        savePreferences()
    }

    /// Update widget visual style.
    func updateWidgetStyle(_ style: WidgetStyle) {
        state.widgetStyle = style
        savePreferences()
    }

    /// Toggle decorative glyph identity elements in widgets.
    func updateWidgetDecorativeGlyphsEnabled(_ isEnabled: Bool) {
        state.widgetDecorativeGlyphsEnabled = isEnabled
        savePreferences()
    }

    /// Update visual theme
    func updateTheme(_ theme: AppTheme) {
        state.selectedTheme = theme
        savePreferences()
    }

    /// Apply a curated script/font preset.
    func applyPreset(_ preset: ReadingPreset) {
        state.selectedScript = preset.script
        state.selectedFont = preset.font
        state.lastUsedPreset = preset
        state.errorMessage = nil
        savePreferences()
    }

    /// Restore the most recently used preset.
    func restoreLastUsedPreset() {
        guard let preset = state.lastUsedPreset else { return }
        applyPreset(preset)
    }

    /// Reset settings to default values.
    func resetToDefaults() {
        state.selectedScript = .elder
        state.selectedFont = .noto
        state.selectedTheme = .obsidian
        state.widgetMode = .daily
        state.widgetStyle = .runeFirst
        state.widgetDecorativeGlyphsEnabled = true
        state.errorMessage = nil
        savePreferences()
    }

    /// Preview text for a specific preset card.
    func presetPreviewRunicText(for preset: ReadingPreset) -> String {
        RunicTransliterator.transliterate(preset.previewLatinText, to: preset.script)
    }

    // MARK: - Private Methods

    private func loadPreferences() async {
        state.isLoading = true
        state.errorMessage = nil

        do {
            preferences = try UserPreferences.getOrCreate(in: modelContext)

            state.selectedScript = preferences?.selectedScript ?? .elder
            state.selectedFont = preferences?.selectedFont ?? .noto
            state.widgetMode = preferences?.widgetMode ?? .daily
            state.widgetStyle = preferences?.widgetStyle ?? .runeFirst
            state.widgetDecorativeGlyphsEnabled = preferences?.widgetDecorativeGlyphsEnabled ?? true
            state.selectedTheme = preferences?.selectedTheme ?? .obsidian
            state.lastUsedPreset = preferences?.lastUsedPreset

            state.isLoading = false
        } catch {
            state.errorMessage = "Failed to load preferences: \(error.localizedDescription)"
            state.isLoading = false
        }
    }

    private func savePreferences() {
        guard let preferences = preferences else { return }

        preferences.selectedScript = state.selectedScript
        preferences.selectedFont = state.selectedFont
        preferences.widgetMode = state.widgetMode
        preferences.widgetStyle = state.widgetStyle
        preferences.widgetDecorativeGlyphsEnabled = state.widgetDecorativeGlyphsEnabled
        preferences.selectedTheme = state.selectedTheme
        preferences.lastUsedPreset = state.lastUsedPreset

        do {
            try modelContext.save()
            NotificationCenter.default.post(name: .preferencesDidChange, object: nil)
        } catch {
            state.errorMessage = "Failed to save preferences: \(error.localizedDescription)"
        }
    }
}

// MARK: - Preview Helper

extension SettingsViewModel {
    /// Create a view model for SwiftUI previews
    static func preview() -> SettingsViewModel {
        let container = ModelContainerHelper.createPlaceholderContainer()
        return SettingsViewModel(modelContext: container.mainContext)
    }
}
