//
//  QuoteViewModel+Translation.swift
//  RunicQuotes
//
//  Created by Codex on 2026-03-13.
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
            let resolvedRunicText = await preferredRunicText(for: quote)
            updateDisplayedRunicText(resolvedRunicText)
            updateCollectionCovers(using: cachedQuotes)
        }
    }

    func preferredRunicText(for quote: QuoteRecord) async -> String {
        if let cachedTranslation = try? await translationProvider.latestTranslation(
            for: quote.id,
            script: state.currentScript
        ), cachedTranslation.isAvailable {
            return cachedTranslation.glyphOutput
        }

        if let storedRunic = quote.runicText(for: state.currentScript) {
            return storedRunic
        }

        return RunicTransliterator.transliterate(quote.textLatin, to: state.currentScript)
    }
}
