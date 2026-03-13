//
//  SettingsView.swift
//  RunicQuotes
//
//  Created by Claude on 2025-11-15.
//

import SwiftData
import SwiftUI

/// Settings and preferences view
struct SettingsView: View {
    @StateObject private var viewModel: SettingsViewModel
    @State private var didInitialize = false
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.runicTheme) private var runicTheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var palette: AppThemePalette {
        .themed(runicTheme, for: colorScheme)
    }

    init() {
        _viewModel = StateObject(
            wrappedValue: SettingsViewModel(
                modelContext: ModelContext(ModelContainerHelper.createPlaceholderContainer())
            )
        )
    }

    var body: some View {
        ScreenScaffold(palette: palette) {
            SettingsHeaderView(palette: palette)
            SettingsLivePreviewSectionView(viewModel: viewModel, palette: palette)
            SettingsAppearanceSectionView(viewModel: viewModel, palette: palette)
            SettingsScriptSectionView(viewModel: viewModel, palette: palette)
            SettingsTypographySectionView(viewModel: viewModel, palette: palette)
            SettingsWidgetSectionView(viewModel: viewModel, palette: palette)
            SettingsAccessibilitySectionView(
                palette: palette,
                reduceTransparency: reduceTransparency,
                reduceMotion: reduceMotion
            )
            SettingsNavigationLinksSectionView(palette: palette)
            SettingsAboutSectionView(palette: palette)
        }
        .task {
            guard !didInitialize else { return }
            didInitialize = true
            viewModel.configureIfNeeded(modelContext: modelContext)
            viewModel.onAppear()
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [Quote.self, UserPreferences.self], inMemory: true)
}

#Preview("With Data") {
    let container = ModelContainerHelper.createPlaceholderContainer()
    let prefs = UserPreferences(
        selectedScript: .cirth,
        selectedFont: .cirth,
        widgetMode: .random,
        selectedTheme: .nordicDawn,
        lastUsedPreset: .cirthLore
    )
    container.mainContext.insert(prefs)

    return SettingsView()
        .modelContainer(container)
}
