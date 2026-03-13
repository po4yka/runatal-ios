//
//  SavedFeatureComponent.swift
//  RunicQuotes
//
//  Created by Codex on 2026-03-13.
//

import NeedleFoundation

protocol SavedFeatureDependency: Dependency { }

@MainActor
final class SavedFeatureComponent: Component<SavedFeatureDependency> {
    private let quoteProvider: QuoteProvider
    private let preferencesRepository: SwiftDataUserPreferencesRepository

    init(
        parent: Scope,
        quoteProvider: QuoteProvider,
        preferencesRepository: SwiftDataUserPreferencesRepository
    ) {
        self.quoteProvider = quoteProvider
        self.preferencesRepository = preferencesRepository
        super.init(parent: parent)
    }

    var viewModel: SavedQuotesViewModel {
        shared {
            SavedQuotesViewModel(
                quoteProvider: quoteProvider,
                preferencesRepository: preferencesRepository
            )
        }
    }

    func view() -> SavedView {
        SavedView(viewModel: viewModel)
    }
}
