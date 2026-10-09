//
//  QuoteView+Previews.swift
//  RunicQuotes
//
//  Created by Claude on 09.10.26.
//

import SwiftData
import SwiftUI

// MARK: - Preview

private enum QuoteViewPreviewFactory {
    @MainActor
    static func sampleContainer() -> ModelContainer {
        let container = ModelContainerHelper.createPlaceholderContainer()
        let quote = Quote(
            textLatin: "Not all those who wander are lost.",
            author: "J.R.R. Tolkien",
        )
        quote.runicElder = "ᚾᛟᛏ ᚨᛚᛚ ᚦᛟᛋᛖ ᚹᚺᛟ ᚹᚨᚾᛞᛖᚱ ᚨᚱᛖ ᛚᛟᛋᛏ"
        container.mainContext.insert(quote)
        return container
    }
}

#Preview {
    QuoteView(
        viewModel: QuoteViewModel.preview(),
        createEditQuoteViewBuilder: CreateEditQuoteViewBuilder { mode, onSaved in
            CreateEditQuoteView(
                viewModel: CreateEditQuoteViewModel.preview(mode: mode),
                mode: mode,
                onSaved: onSaved,
            )
        },
        translationViewBuilder: TranslationViewBuilder {
            TranslationView(viewModel: TranslationViewModel.preview())
        },
    )
    .modelContainer(for: [Quote.self, UserPreferences.self], inMemory: true)
    .environmentObject(ReadingAppearanceController.preview())
    .environmentObject(QuoteNavigationCoordinator.preview())
    .environmentObject(FeatureDiscoveryController.preview())
    .environmentObject(QuoteNavigationCoordinator.preview())
}

#Preview("With Sample Data") {
    QuoteView(
        viewModel: QuoteViewModel.preview(),
        createEditQuoteViewBuilder: CreateEditQuoteViewBuilder { mode, onSaved in
            CreateEditQuoteView(
                viewModel: CreateEditQuoteViewModel.preview(mode: mode),
                mode: mode,
                onSaved: onSaved,
            )
        },
        translationViewBuilder: TranslationViewBuilder {
            TranslationView(viewModel: TranslationViewModel.preview())
        },
    )
    .modelContainer(QuoteViewPreviewFactory.sampleContainer())
    .environmentObject(FeatureDiscoveryController.preview())
    .environmentObject(QuoteNavigationCoordinator.preview())
}
