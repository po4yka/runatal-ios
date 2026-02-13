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
    // MARK: - Published State

    @Published var selectedScript: RunicScript = .elder
    @Published var selectedFont: RunicFont = .noto
    @Published var widgetMode: WidgetMode = .daily
    @Published var widgetStyle: WidgetStyle = .runeFirst
    @Published var widgetDecorativeGlyphsEnabled = true
    @Published var selectedTheme: AppTheme = .obsidian
    @Published private(set) var lastUsedPreset: ReadingPreset?

    @Published private(set) var errorMessage: String?
    @Published private(set) var isLoading: Bool = false

    // MARK: - Dependencies

    private var modelContext: ModelContext
    private var preferences: UserPreferences?
    private var isConfiguredWithEnvironmentContext = false

    // MARK: - Computed Properties

    /// Get available fonts for the current script
    var availableFonts: [RunicFont] {
        RunicFont.allCases.filter { font in
            font.isCompatible(with: selectedScript)
        }
    }

    /// Get the current font name for display
    var currentFontName: String {
        RunicFontConfiguration.fontName(for: selectedScript, font: selectedFont)
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
        RunicTransliterator.transliterate(livePreviewLatinText, to: selectedScript)
    }

    /// Whether reset action should be active.
    var isAtDefaults: Bool {
        selectedScript == .elder &&
        selectedFont == .noto &&
        widgetMode == .daily &&
        widgetStyle == .runeFirst &&
        widgetDecorativeGlyphsEnabled &&
        selectedTheme == .obsidian
    }

    /// Whether last preset restore action can run.
    var canRestoreLastPreset: Bool {
        lastUsedPreset != nil
    }

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Public API

    /// Load preferences when view appears
    func onAppear() {
        isLoading = true
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
        selectedScript = script

        // Ensure font compatibility
        if !selectedFont.isCompatible(with: script) {
            selectedFont = RunicFontConfiguration.recommendedFont(for: script)
        }

        savePreferences()
    }

    /// Update the selected font
    func updateFont(_ font: RunicFont) {
        guard font.isCompatible(with: selectedScript) else {
            errorMessage = "\(font.displayName) is not compatible with \(selectedScript.displayName)"
            return
        }

        selectedFont = font
        savePreferences()
    }

    /// Update widget mode
    func updateWidgetMode(_ mode: WidgetMode) {
        widgetMode = mode
        savePreferences()
    }

    /// Update widget visual style.
    func updateWidgetStyle(_ style: WidgetStyle) {
        widgetStyle = style
        savePreferences()
    }

    /// Toggle decorative glyph identity elements in widgets.
    func updateWidgetDecorativeGlyphsEnabled(_ isEnabled: Bool) {
        widgetDecorativeGlyphsEnabled = isEnabled
        savePreferences()
    }

    /// Update visual theme
    func updateTheme(_ theme: AppTheme) {
        selectedTheme = theme
        savePreferences()
    }

    /// Apply a curated script/font preset.
    func applyPreset(_ preset: ReadingPreset) {
        selectedScript = preset.script
        selectedFont = preset.font
        lastUsedPreset = preset
        errorMessage = nil
        savePreferences()
    }

    /// Restore the most recently used preset.
    func restoreLastUsedPreset() {
        guard let lastUsedPreset else { return }
        applyPreset(lastUsedPreset)
    }

    /// Reset settings to default values.
    func resetToDefaults() {
        selectedScript = .elder
        selectedFont = .noto
        selectedTheme = .obsidian
        widgetMode = .daily
        widgetStyle = .runeFirst
        widgetDecorativeGlyphsEnabled = true
        errorMessage = nil
        savePreferences()
    }

    /// Preview text for a specific preset card.
    func presetPreviewRunicText(for preset: ReadingPreset) -> String {
        RunicTransliterator.transliterate(preset.previewLatinText, to: preset.script)
    }

    // MARK: - Private Methods

    private func loadPreferences() async {
        isLoading = true
        errorMessage = nil

        do {
            preferences = try UserPreferences.getOrCreate(in: modelContext)

            // Update published properties
            selectedScript = preferences?.selectedScript ?? .elder
            selectedFont = preferences?.selectedFont ?? .noto
            widgetMode = preferences?.widgetMode ?? .daily
            widgetStyle = preferences?.widgetStyle ?? .runeFirst
            widgetDecorativeGlyphsEnabled = preferences?.widgetDecorativeGlyphsEnabled ?? true
            selectedTheme = preferences?.selectedTheme ?? .obsidian
            lastUsedPreset = preferences?.lastUsedPreset

            isLoading = false
        } catch {
            errorMessage = "Failed to load preferences: \(error.localizedDescription)"
            isLoading = false
        }
    }

    private func savePreferences() {
        guard let preferences = preferences else { return }

        preferences.selectedScript = selectedScript
        preferences.selectedFont = selectedFont
        preferences.widgetMode = widgetMode
        preferences.widgetStyle = widgetStyle
        preferences.widgetDecorativeGlyphsEnabled = widgetDecorativeGlyphsEnabled
        preferences.selectedTheme = selectedTheme
        preferences.lastUsedPreset = lastUsedPreset

        do {
            try modelContext.save()
            NotificationCenter.default.post(name: .preferencesDidChange, object: nil)
        } catch {
            errorMessage = "Failed to save preferences: \(error.localizedDescription)"
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
