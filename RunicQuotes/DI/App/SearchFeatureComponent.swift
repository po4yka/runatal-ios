//
//  SearchFeatureComponent.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import NeedleFoundation

protocol SearchFeatureDependency: Dependency {}

@MainActor
final class SearchFeatureComponent: Component<SearchFeatureDependency> {
    private let quoteProvider: QuoteProvider

    init(parent: Scope, quoteProvider: QuoteProvider) {
        self.quoteProvider = quoteProvider
        super.init(parent: parent)
    }

    var viewModel: SearchViewModel {
        shared {
            SearchViewModel(quoteProvider: self.quoteProvider)
        }
    }

    func view() -> SearchView {
        SearchView(viewModel: self.viewModel)
    }
}
