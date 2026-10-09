//
//  QuoteViewModel+Translation.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import Foundation

extension QuoteViewModel {
    func onTranslationCacheUpdated(for quoteID: UUID?) {
        guard let currentQuoteID = state.currentQuoteID else { return }
        if let quoteID, quoteID != currentQuoteID {
            return
        }

        guard let quote = cachedQuotes.first(where: { $0.id == currentQuoteID }) else {
            return
        }

        Task {
            let presentation = await preferredRunicPresentation(for: quote)
            updateDisplayedRunicPresentation(presentation)
            updateCollectionCovers(using: cachedQuotes)
        }
    }

    func preferredRunicPresentation(for quote: QuoteRecord) async -> ResolvedRunicPresentation {
        let script = self.state.currentScript
        let cache = try? await self.translationProvider.latestTranslation(for: quote.id, script: script)
        return RunicPresentationResolver.resolve(RunicPresentationInput(quote: quote, script: script), currentCache: cache)
    }

    func preferredRunicText(for quote: QuoteRecord) async -> String {
        await self.preferredRunicPresentation(for: quote).text
    }
}
