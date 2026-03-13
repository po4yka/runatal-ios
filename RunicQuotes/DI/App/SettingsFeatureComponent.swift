//
//  SettingsFeatureComponent.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import NeedleFoundation

protocol SettingsFeatureDependency: Dependency {}

@MainActor
final class SettingsFeatureComponent: Component<SettingsFeatureDependency> {
    private let preferencesRepository: SwiftDataUserPreferencesRepository
    private let translationViewBuilder: TranslationViewBuilder
    private let archiveViewBuilder: ArchiveViewBuilder

    init(
        parent: Scope,
        preferencesRepository: SwiftDataUserPreferencesRepository,
        translationViewBuilder: TranslationViewBuilder,
        archiveViewBuilder: ArchiveViewBuilder,
    ) {
        self.preferencesRepository = preferencesRepository
        self.translationViewBuilder = translationViewBuilder
        self.archiveViewBuilder = archiveViewBuilder
        super.init(parent: parent)
    }

    var viewModel: SettingsViewModel {
        shared {
            SettingsViewModel(preferencesRepository: self.preferencesRepository)
        }
    }

    func view() -> SettingsView {
        SettingsView(
            viewModel: self.viewModel,
            translationViewBuilder: self.translationViewBuilder,
            archiveViewBuilder: self.archiveViewBuilder,
        )
    }
}
