//
//  SettingsViewModel.swift
//  RunicQuotes
//
//  Created by Claude on 07.10.25.
//

import Combine
import Foundation
import SwiftData
import SwiftUI

/// ViewModel for the settings screen
@MainActor
final class SettingsViewModel: ObservableObject {
    // MARK: - State

    struct State {
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

    private let preferencesRepository: any UserPreferencesRepository
    private var preferences = UserPreferencesSnapshot()

    // MARK: - Computed Properties

    /// Get available fonts for the current script
    var availableFonts: [RunicFont] {
        RunicFont.allCases.filter { font in
            font.isCompatible(with: self.state.selectedScript)
        }
    }

    /// Get the current font name for display
    var currentFontName: String {
        RunicFontConfiguration.fontName(for: self.state.selectedScript, font: self.state.selectedFont)
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
        RunicTransliterator.transliterate(self.livePreviewLatinText, to: self.state.selectedScript)
    }

    /// Whether reset action should be active.
    var isAtDefaults: Bool {
        self.state.selectedScript == .elder &&
            self.state.selectedFont == .noto &&
            self.state.widgetMode == .daily &&
            self.state.widgetStyle == .runeFirst &&
            self.state.widgetDecorativeGlyphsEnabled &&
            self.state.selectedTheme == .obsidian
    }

    /// Whether last preset restore action can run.
    var canRestoreLastPreset: Bool {
        self.state.lastUsedPreset != nil
    }

    // MARK: - Initialization

    init(preferencesRepository: any UserPreferencesRepository) {
        self.preferencesRepository = preferencesRepository
    }

    // MARK: - Public API

    /// Load preferences when view appears
    func onAppear() {
        self.state.isLoading = true
        Task {
            await self.loadPreferences()
        }
    }

    /// Update the selected script
    func updateScript(_ script: RunicScript) {
        self.state.selectedScript = script

        // Ensure font compatibility
        if !self.state.selectedFont.isCompatible(with: script) {
            self.state.selectedFont = RunicFontConfiguration.recommendedFont(for: script)
        }

        self.savePreferences([.script(script)])
    }

    /// Update the selected font
    func updateFont(_ font: RunicFont) {
        guard font.isCompatible(with: self.state.selectedScript) else {
            self.state.errorMessage = "\(font.displayName) is not compatible with \(self.state.selectedScript.displayName)"
            return
        }

        self.state.selectedFont = font
        self.savePreferences([.font(font)])
    }

    /// Update widget mode
    func updateWidgetMode(_ mode: WidgetMode) {
        self.state.widgetMode = mode
        self.savePreferences([.widgetMode(mode)])
    }

    /// Update widget visual style.
    func updateWidgetStyle(_ style: WidgetStyle) {
        self.state.widgetStyle = style
        self.savePreferences([.widgetStyle(style)])
    }

    /// Toggle decorative glyph identity elements in widgets.
    func updateWidgetDecorativeGlyphsEnabled(_ isEnabled: Bool) {
        self.state.widgetDecorativeGlyphsEnabled = isEnabled
        self.savePreferences([.decorativeGlyphs(isEnabled)])
    }

    /// Update visual theme
    func updateTheme(_ theme: AppTheme) {
        self.state.selectedTheme = theme
        self.savePreferences([.theme(theme)])
    }

    /// Apply a curated script/font preset.
    func applyPreset(_ preset: ReadingPreset) {
        self.state.selectedScript = preset.script
        self.state.selectedFont = preset.font
        self.state.lastUsedPreset = preset
        self.state.errorMessage = nil
        self.savePreferences([.preset(preset)])
    }

    /// Restore the most recently used preset.
    func restoreLastUsedPreset() {
        guard let preset = state.lastUsedPreset else { return }
        self.applyPreset(preset)
    }

    /// Reset settings to default values.
    func resetToDefaults() {
        self.state.selectedScript = .elder
        self.state.selectedFont = .noto
        self.state.selectedTheme = .obsidian
        self.state.widgetMode = .daily
        self.state.widgetStyle = .runeFirst
        self.state.widgetDecorativeGlyphsEnabled = true
        self.state.errorMessage = nil
        self.savePreferences([.resetReadingSettings])
    }

    /// Preview text for a specific preset card.
    func presetPreviewRunicText(for preset: ReadingPreset) -> String {
        RunicTransliterator.transliterate(preset.previewLatinText, to: preset.script)
    }

    // MARK: - Private Methods

    private func loadPreferences() async {
        self.state.isLoading = true
        self.state.errorMessage = nil

        do {
            self.preferences = try self.preferencesRepository.snapshot()

            self.state.selectedScript = self.preferences.selectedScript
            self.state.selectedFont = self.preferences.selectedFont
            self.state.widgetMode = self.preferences.widgetMode
            self.state.widgetStyle = self.preferences.widgetStyle
            self.state.widgetDecorativeGlyphsEnabled = self.preferences.widgetDecorativeGlyphsEnabled
            self.state.selectedTheme = self.preferences.selectedTheme
            self.state.lastUsedPreset = self.preferences.lastUsedPreset
            UserDefaults.standard.set(
                self.state.selectedTheme.rawValue,
                forKey: AppConstants.selectedThemeStorageKey,
            )

            self.state.isLoading = false
        } catch {
            self.state.errorMessage = "Failed to load preferences: \(error.localizedDescription)"
            self.state.isLoading = false
        }
    }

    private func savePreferences(_ mutations: [UserPreferencesMutation]) {
        do {
            self.preferences = try self.preferencesRepository.apply(mutations)
            self.state.selectedScript = self.preferences.selectedScript
            self.state.selectedFont = self.preferences.selectedFont
            self.state.widgetMode = self.preferences.widgetMode
            self.state.widgetStyle = self.preferences.widgetStyle
            self.state.widgetDecorativeGlyphsEnabled = self.preferences.widgetDecorativeGlyphsEnabled
            self.state.selectedTheme = self.preferences.selectedTheme
            self.state.lastUsedPreset = self.preferences.lastUsedPreset
            UserDefaults.standard.set(
                self.state.selectedTheme.rawValue,
                forKey: AppConstants.selectedThemeStorageKey,
            )
        } catch {
            self.state.errorMessage = "Failed to save preferences: \(error.localizedDescription)"
        }
    }
}

// MARK: - Preview Helper

extension SettingsViewModel {
    /// Create a view model for SwiftUI previews
    static func preview() -> SettingsViewModel {
        let container = ModelContainerHelper.createPlaceholderContainer()
        return SettingsViewModel(
            preferencesRepository: SwiftDataUserPreferencesRepository(modelContext: container.mainContext),
        )
    }
}
