//
//  SettingsViewModelTests.swift
//  RunicQuotes
//
//  Created by Claude on 13.02.26.
//

@testable import RunicQuotes
import SwiftData
import Testing

@MainActor
@Suite(.serialized, .tags(.viewModel))
struct SettingsViewModelTests {
    @Test
    func applyPresetUpdatesScriptFontAndLastUsedPreset() async throws {
        let (viewModel, context) = try makeViewModel()
        viewModel.onAppear()

        #expect(await TestSupport.eventually { !viewModel.state.isLoading })

        viewModel.applyPreset(.youngerCarved)

        #expect(viewModel.state.selectedScript == .younger)
        #expect(viewModel.state.selectedFont == .babelstone)
        #expect(viewModel.canRestoreLastPreset)
        #expect(try UserPreferences.getOrCreate(in: context).lastUsedPreset == .youngerCarved)
    }

    @Test
    func restoreLastUsedPresetRestoresPreviousCombination() async throws {
        let (viewModel, _) = try makeViewModel()
        viewModel.onAppear()

        #expect(await TestSupport.eventually { !viewModel.state.isLoading })

        viewModel.applyPreset(.cirthLore)
        viewModel.updateScript(.elder)
        viewModel.updateFont(.noto)

        #expect(viewModel.state.selectedScript == .elder)
        #expect(viewModel.state.selectedFont == .noto)

        viewModel.restoreLastUsedPreset()

        #expect(viewModel.state.selectedScript == .cirth)
        #expect(viewModel.state.selectedFont == .cirth)
    }

    @Test
    func resetToDefaultsRestoresDefaultSettings() async throws {
        let (viewModel, _) = try makeViewModel()
        viewModel.onAppear()

        #expect(await TestSupport.eventually { !viewModel.state.isLoading })

        viewModel.applyPreset(.youngerCarved)
        viewModel.updateTheme(.nordicDawn)
        viewModel.updateWidgetMode(.random)
        #expect(!viewModel.isAtDefaults)

        viewModel.resetToDefaults()

        #expect(viewModel.state.selectedScript == .elder)
        #expect(viewModel.state.selectedFont == .noto)
        #expect(viewModel.state.selectedTheme == .obsidian)
        #expect(viewModel.state.widgetMode == .daily)
        #expect(viewModel.isAtDefaults)
    }

    private func makeViewModel() throws -> (SettingsViewModel, ModelContext) {
        let context = try TestSupport.makeModelContext()
        return (
            SettingsViewModel(preferencesRepository: SwiftDataUserPreferencesRepository(modelContext: context)),
            context,
        )
    }
}
