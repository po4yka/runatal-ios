//
//  TranslationFeatureComponent.swift
//  RunicQuotes
//
//  Created by Codex on 2026-03-13.
//

import NeedleFoundation

protocol TranslationFeatureDependency: Dependency { }

@MainActor
final class TranslationFeatureComponent: Component<TranslationFeatureDependency> {
    private let quoteRepository: SwiftDataQuoteRepository
    private let translationRepository: SwiftDataTranslationRepository
    private let preferencesRepository: SwiftDataUserPreferencesRepository
    private let translationService: HistoricalTranslationService

    init(
        parent: Scope,
        quoteRepository: SwiftDataQuoteRepository,
        translationRepository: SwiftDataTranslationRepository,
        preferencesRepository: SwiftDataUserPreferencesRepository,
        translationService: HistoricalTranslationService
    ) {
        self.quoteRepository = quoteRepository
        self.translationRepository = translationRepository
        self.preferencesRepository = preferencesRepository
        self.translationService = translationService
        super.init(parent: parent)
    }

    var viewModel: TranslationViewModel {
        TranslationViewModel(
            quoteRepository: quoteRepository,
            translationRepository: translationRepository,
            preferencesRepository: preferencesRepository,
            translationService: translationService
        )
    }

    func view() -> TranslationView {
        TranslationView(viewModel: viewModel)
    }
}
