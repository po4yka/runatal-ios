//
//  TranslationFeatureComponent.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import NeedleFoundation

protocol TranslationFeatureDependency: Dependency {}

@MainActor
final class TranslationFeatureComponent: Component<TranslationFeatureDependency> {
    private let quoteRepository: SwiftDataQuoteRepository
    private let preferencesRepository: SwiftDataUserPreferencesRepository
    private let translationService: HistoricalTranslationService

    init(
        parent: Scope,
        quoteRepository: SwiftDataQuoteRepository,
        preferencesRepository: SwiftDataUserPreferencesRepository,
        translationService: HistoricalTranslationService,
    ) {
        self.quoteRepository = quoteRepository
        self.preferencesRepository = preferencesRepository
        self.translationService = translationService
        super.init(parent: parent)
    }

    var viewModel: TranslationViewModel {
        TranslationViewModel(
            quoteRepository: self.quoteRepository,
            preferencesRepository: self.preferencesRepository,
            translationService: self.translationService,
        )
    }

    func view() -> TranslationView {
        TranslationView(viewModel: self.viewModel)
    }
}
