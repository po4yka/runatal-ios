//
//  QuoteViewModel+Translation.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import Foundation

extension QuoteViewModel {
    func onTranslationCacheUpdated(for quoteID: UUID?) {
        if let current = self.state.currentQuoteID, let quoteID, current != quoteID {
            return
        }
        self.onLibraryChanged()
    }

    func preferredRunicPresentation(for quote: QuoteRecord, script: RunicScript? = nil) async -> ResolvedRunicPresentation {
        let script = script ?? self.state.currentScript
        let cache = try? await self.translationProvider.latestTranslation(for: quote.id, script: script)
        return RunicPresentationResolver.resolve(RunicPresentationInput(quote: quote, script: script), currentCache: cache)
    }

    func preferredRunicText(for quote: QuoteRecord) async -> String {
        await self.preferredRunicPresentation(for: quote).text
    }
}
