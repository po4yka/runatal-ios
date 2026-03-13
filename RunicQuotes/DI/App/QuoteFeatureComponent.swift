//
//  QuoteFeatureComponent.swift
//  RunicQuotes
//
//  Created by Codex on 2026-03-13.
//

import NeedleFoundation

protocol QuoteFeatureDependency: Dependency { }

@MainActor
final class QuoteFeatureComponent: Component<QuoteFeatureDependency> {
    private let quoteProvider: QuoteProvider
    private let translationProvider: TranslationProvider
    private let preferencesRepository: SwiftDataUserPreferencesRepository
    private let createEditQuoteViewBuilder: CreateEditQuoteViewBuilder
    private let translationViewBuilder: TranslationViewBuilder

    init(
        parent: Scope,
        quoteProvider: QuoteProvider,
        translationProvider: TranslationProvider,
        preferencesRepository: SwiftDataUserPreferencesRepository,
        createEditQuoteViewBuilder: CreateEditQuoteViewBuilder,
        translationViewBuilder: TranslationViewBuilder
    ) {
        self.quoteProvider = quoteProvider
        self.translationProvider = translationProvider
        self.preferencesRepository = preferencesRepository
        self.createEditQuoteViewBuilder = createEditQuoteViewBuilder
        self.translationViewBuilder = translationViewBuilder
        super.init(parent: parent)
    }

    var viewModel: QuoteViewModel {
        shared {
            QuoteViewModel(
                quoteProvider: quoteProvider,
                translationProvider: translationProvider,
                preferencesRepository: preferencesRepository
            )
        }
    }

    func view() -> QuoteView {
        QuoteView(
            viewModel: viewModel,
            createEditQuoteViewBuilder: createEditQuoteViewBuilder,
            translationViewBuilder: translationViewBuilder
        )
    }
}
