//
//  SavedFeatureComponent.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import NeedleFoundation

protocol SavedFeatureDependency: Dependency {}

@MainActor
final class SavedFeatureComponent: Component<SavedFeatureDependency> {
    private let quoteProvider: QuoteProvider
    private let preferencesRepository: SwiftDataUserPreferencesRepository

    init(
        parent: Scope,
        quoteProvider: QuoteProvider,
        preferencesRepository: SwiftDataUserPreferencesRepository,
    ) {
        self.quoteProvider = quoteProvider
        self.preferencesRepository = preferencesRepository
        super.init(parent: parent)
    }

    var viewModel: SavedQuotesViewModel {
        shared {
            SavedQuotesViewModel(
                quoteProvider: self.quoteProvider,
                preferencesRepository: self.preferencesRepository,
            )
        }
    }

    func view() -> SavedView {
        SavedView(viewModel: self.viewModel)
    }
}
