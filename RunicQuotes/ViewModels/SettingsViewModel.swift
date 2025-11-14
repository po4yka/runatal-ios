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

    @Published private(set) var errorMessage: String?
    @Published private(set) var isLoading: Bool = false

    // MARK: - Dependencies

    private let modelContext: ModelContext
    private var preferences: UserPreferences?

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

        do {
            try modelContext.save()
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
