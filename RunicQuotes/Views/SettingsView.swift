//
//  SettingsView.swift
//  RunicQuotes
//
//  Created by Claude on 07.10.25.
//

import SwiftData
import SwiftUI

/// Settings and preferences view
struct SettingsView: View {
    @StateObject private var viewModel: SettingsViewModel
    @State private var didInitialize = false
    @State private var showReplayAlert = false
    @State private var replayAlertMessage = ""
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.runicTheme) private var runicTheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var featureDiscoveryController: FeatureDiscoveryController
    private let translationViewBuilder: TranslationViewBuilder
    private let archiveViewBuilder: ArchiveViewBuilder

    private var palette: AppThemePalette {
        .themed(self.runicTheme, for: self.colorScheme)
    }

    init(
        viewModel: SettingsViewModel,
        translationViewBuilder: TranslationViewBuilder,
        archiveViewBuilder: ArchiveViewBuilder,
    ) {
        self.translationViewBuilder = translationViewBuilder
        self.archiveViewBuilder = archiveViewBuilder
        _viewModel = StateObject(
            wrappedValue: viewModel,
        )
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [self.palette.canvasBase, self.palette.canvasSecondary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing,
            )
            .ignoresSafeArea()

            Form {
                Section {
                    SettingsHeaderView(palette: self.palette)
                }

                Section {
                    SettingsLivePreviewSectionView(viewModel: self.viewModel, palette: self.palette)
                }

                Section {
                    SettingsAppearanceSectionView(viewModel: self.viewModel, palette: self.palette)
                    SettingsScriptSectionView(viewModel: self.viewModel, palette: self.palette)
                    SettingsTypographySectionView(
                        viewModel: self.viewModel,
                        palette: self.palette,
                        tipRefreshID: self.featureDiscoveryController.refreshID,
                    )
                    SettingsWidgetSectionView(
                        viewModel: self.viewModel,
                        palette: self.palette,
                        tipRefreshID: self.featureDiscoveryController.refreshID,
                    )
                    SettingsAccessibilitySectionView(
                        palette: self.palette,
                        reduceTransparency: self.reduceTransparency,
                        reduceMotion: self.reduceMotion,
                    )
                }

                Section {
                    SettingsNavigationLinksSectionView(palette: self.palette)
                    SettingsAboutSectionView(palette: self.palette, showTipsAgain: self.replayTips)
                }
            }
            .scrollContentBackground(.hidden)
        }
        .task {
            guard !self.didInitialize else { return }
            self.didInitialize = true
            self.viewModel.onAppear()
        }
        .navigationDestination(for: SettingsDestination.self) { destination in
            switch destination {
            case .translation:
                self.translationViewBuilder.makeView()
            case .runeReference:
                RuneReferenceView()
            case .archive:
                self.archiveViewBuilder.makeView()
            }
        }
        .alert("Tips Updated", isPresented: self.$showReplayAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(self.replayAlertMessage)
        }
    }

    private func replayTips() {
        do {
            try self.featureDiscoveryController.replayTips()
            self.replayAlertMessage = "Contextual tips are ready to appear again."
        } catch {
            self.replayAlertMessage = "Tip replay could not be reset right now."
        }

        self.showReplayAlert = true
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
            lastUsedPreset: .cirthLore,
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
        },
    )
    .modelContainer(for: [Quote.self, UserPreferences.self], inMemory: true)
    .environmentObject(FeatureDiscoveryController.preview())
}

#Preview("With Data") {
    SettingsView(
        viewModel: SettingsViewModel.preview(),
        translationViewBuilder: TranslationViewBuilder {
            TranslationView(viewModel: TranslationViewModel.preview())
        },
        archiveViewBuilder: ArchiveViewBuilder {
            ArchiveView(viewModel: ArchiveViewModel.preview())
        },
    )
    .modelContainer(SettingsViewPreviewFactory.container())
    .environmentObject(FeatureDiscoveryController.preview())
}
