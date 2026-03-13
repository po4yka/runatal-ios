//
//  SettingsFeatureComponent.swift
//  RunicQuotes
//
//  Created by Codex on 2026-03-13.
//

import NeedleFoundation

protocol SettingsFeatureDependency: Dependency { }

@MainActor
final class SettingsFeatureComponent: Component<SettingsFeatureDependency> {
    private let preferencesRepository: SwiftDataUserPreferencesRepository
    private let translationViewBuilder: TranslationViewBuilder
    private let archiveViewBuilder: ArchiveViewBuilder

    init(
        parent: Scope,
        preferencesRepository: SwiftDataUserPreferencesRepository,
        translationViewBuilder: TranslationViewBuilder,
        archiveViewBuilder: ArchiveViewBuilder
    ) {
        self.preferencesRepository = preferencesRepository
        self.translationViewBuilder = translationViewBuilder
        self.archiveViewBuilder = archiveViewBuilder
        super.init(parent: parent)
    }

    var viewModel: SettingsViewModel {
        shared {
            SettingsViewModel(preferencesRepository: preferencesRepository)
        }
    }

    func view() -> SettingsView {
        SettingsView(
            viewModel: viewModel,
            translationViewBuilder: translationViewBuilder,
            archiveViewBuilder: archiveViewBuilder
        )
    }
}
