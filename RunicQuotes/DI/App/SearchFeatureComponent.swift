//
//  SearchFeatureComponent.swift
//  RunicQuotes
//
//  Created by Codex on 2026-03-13.
//

import NeedleFoundation

protocol SearchFeatureDependency: Dependency { }

@MainActor
final class SearchFeatureComponent: Component<SearchFeatureDependency> {
    private let quoteProvider: QuoteProvider

    init(parent: Scope, quoteProvider: QuoteProvider) {
        self.quoteProvider = quoteProvider
        super.init(parent: parent)
    }

    var viewModel: SearchViewModel {
        shared {
            SearchViewModel(quoteProvider: quoteProvider)
        }
    }

    func view() -> SearchView {
        SearchView(viewModel: viewModel)
    }
}
