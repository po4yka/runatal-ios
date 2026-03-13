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
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.runicTheme) private var runicTheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let translationViewBuilder: TranslationViewBuilder
    private let archiveViewBuilder: ArchiveViewBuilder

    private var palette: AppThemePalette {
        .themed(runicTheme, for: colorScheme)
    }

    init(
        viewModel: SettingsViewModel,
        translationViewBuilder: TranslationViewBuilder,
        archiveViewBuilder: ArchiveViewBuilder
    ) {
        self.translationViewBuilder = translationViewBuilder
        self.archiveViewBuilder = archiveViewBuilder
        _viewModel = StateObject(
            wrappedValue: viewModel
        )
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [palette.canvasBase, palette.canvasSecondary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Form {
                Section {
                    SettingsHeaderView(palette: palette)
                }

                Section {
                    SettingsLivePreviewSectionView(viewModel: viewModel, palette: palette)
                }

                Section {
                    SettingsAppearanceSectionView(viewModel: viewModel, palette: palette)
                    SettingsScriptSectionView(viewModel: viewModel, palette: palette)
                    SettingsTypographySectionView(viewModel: viewModel, palette: palette)
                    SettingsWidgetSectionView(viewModel: viewModel, palette: palette)
                    SettingsAccessibilitySectionView(
                        palette: palette,
                        reduceTransparency: reduceTransparency,
                        reduceMotion: reduceMotion
                    )
                }

                Section {
                    SettingsNavigationLinksSectionView(palette: palette)
                    SettingsAboutSectionView(palette: palette)
                }
            }
            .scrollContentBackground(.hidden)
        }
        .task {
            guard !didInitialize else { return }
            didInitialize = true
            viewModel.onAppear()
        }
        .navigationDestination(for: SettingsDestination.self) { destination in
            switch destination {
            case .translation:
                translationViewBuilder.makeView()
            case .runeReference:
                RuneReferenceView()
            case .archive:
                archiveViewBuilder.makeView()
            }
        }
    }
}

private enum SettingsViewPreviewFactory {
    @MainActor
    static func container() -> ModelContainer {
        let container = ModelContainerHelper.createPlaceholderContainer()
        let prefs = UserPreferences(
            selectedScript: .cirth,
            selectedFont: .cirth,
            widgetMode: .random,
            selectedTheme: .nordicDawn,
            lastUsedPreset: .cirthLore
        )
        container.mainContext.insert(prefs)
        return container
    }
}

#Preview {
    SettingsView(
        viewModel: SettingsViewModel.preview(),
        translationViewBuilder: TranslationViewBuilder {
            TranslationView(viewModel: TranslationViewModel.preview())
        },
        archiveViewBuilder: ArchiveViewBuilder {
            ArchiveView(viewModel: ArchiveViewModel.preview())
        }
    )
        .modelContainer(for: [Quote.self, UserPreferences.self], inMemory: true)
}

#Preview("With Data") {
    SettingsView(
        viewModel: SettingsViewModel.preview(),
        translationViewBuilder: TranslationViewBuilder {
            TranslationView(viewModel: TranslationViewModel.preview())
        },
        archiveViewBuilder: ArchiveViewBuilder {
            ArchiveView(viewModel: ArchiveViewModel.preview())
        }
    )
    .modelContainer(SettingsViewPreviewFactory.container())
}
