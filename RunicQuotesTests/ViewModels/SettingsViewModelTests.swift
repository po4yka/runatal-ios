//
//  SettingsViewModelTests.swift
//  RunicQuotesTests
//
//  Created by Codex on 2026-02-13.
//

import XCTest
import SwiftData
@testable import RunicQuotes

final class SettingsViewModelTests: XCTestCase {
    @MainActor
    func testApplyPresetUpdatesScriptFontAndLastUsedPreset() async throws {
        let (viewModel, context) = try makeViewModel()
        viewModel.onAppear()

        await waitUntil("settings load completes") {
            !viewModel.state.isLoading
        }

        viewModel.applyPreset(.youngerCarved)

        XCTAssertEqual(viewModel.state.selectedScript, .younger)
        XCTAssertEqual(viewModel.state.selectedFont, .babelstone)
        XCTAssertTrue(viewModel.canRestoreLastPreset)

        let saved = try UserPreferences.getOrCreate(in: context)
        XCTAssertEqual(saved.lastUsedPreset, .youngerCarved)
    }

    @MainActor
    func testRestoreLastUsedPresetRestoresPreviousCombination() async throws {
        let (viewModel, _) = try makeViewModel()
        viewModel.onAppear()

        await waitUntil("settings load completes") {
            !viewModel.state.isLoading
        }

        viewModel.applyPreset(.cirthLore)
        viewModel.updateScript(.elder)
        viewModel.updateFont(.noto)

        XCTAssertEqual(viewModel.state.selectedScript, .elder)
        XCTAssertEqual(viewModel.state.selectedFont, .noto)

        viewModel.restoreLastUsedPreset()

        XCTAssertEqual(viewModel.state.selectedScript, .cirth)
        XCTAssertEqual(viewModel.state.selectedFont, .cirth)
    }

    @MainActor
    func testResetToDefaultsRestoresDefaultSettings() async throws {
        let (viewModel, _) = try makeViewModel()
        viewModel.onAppear()

        await waitUntil("settings load completes") {
            !viewModel.state.isLoading
        }

        viewModel.applyPreset(.youngerCarved)
        viewModel.updateTheme(.nordicDawn)
        viewModel.updateWidgetMode(.random)

        XCTAssertFalse(viewModel.isAtDefaults)

        viewModel.resetToDefaults()

        XCTAssertEqual(viewModel.state.selectedScript, .elder)
        XCTAssertEqual(viewModel.state.selectedFont, .noto)
        XCTAssertEqual(viewModel.state.selectedTheme, .obsidian)
        XCTAssertEqual(viewModel.state.widgetMode, .daily)
        XCTAssertTrue(viewModel.isAtDefaults)
    }

    @MainActor
    private func makeViewModel() throws -> (SettingsViewModel, ModelContext) {
        let schema = Schema([Quote.self, UserPreferences.self, TranslationRecord.self, TranslationBackfillState.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: config)
        let context = ModelContext(container)
        let viewModel = SettingsViewModel(modelContext: context)
        return (viewModel, context)
    }

    @MainActor
    private func waitUntil(
        _ description: String,
        timeoutNanoseconds: UInt64 = 2_000_000_000,
        pollIntervalNanoseconds: UInt64 = 25_000_000,
        condition: () -> Bool
    ) async {
        let deadline = DispatchTime.now().uptimeNanoseconds + timeoutNanoseconds

        while DispatchTime.now().uptimeNanoseconds < deadline {
            if condition() {
                return
            }

            try? await Task.sleep(for: .nanoseconds(pollIntervalNanoseconds))
        }

        XCTFail("Timed out waiting for condition: \(description)")
    }
}
