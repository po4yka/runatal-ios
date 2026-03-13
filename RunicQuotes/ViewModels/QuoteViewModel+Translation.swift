//
//  QuoteViewModel+Translation.swift
//  RunicQuotes
//
//  Created by Codex on 2026-03-13.
//

import Foundation

struct ResolvedRunicPresentation: Sendable {
    let text: String
    let source: RunicPresentationSource
    let evidenceTier: TranslationEvidenceTier?
    let primarySourceLabel: String?
}

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
        if let cachedTranslation = try? await translationProvider.latestTranslation(
            for: quote.id,
            script: state.currentScript
        ), cachedTranslation.isAvailable {
            return ResolvedRunicPresentation(
                text: cachedTranslation.glyphOutput,
                source: .structuredTranslation,
                evidenceTier: cachedTranslation.evidenceTier,
                primarySourceLabel: cachedTranslation.primaryEvidenceLabel
            )
        }

        if let storedRunic = quote.runicText(for: state.currentScript) {
            return ResolvedRunicPresentation(
                text: storedRunic,
                source: .storedTransliteration,
                evidenceTier: nil,
                primarySourceLabel: nil
            )
        }

        return ResolvedRunicPresentation(
            text: RunicTransliterator.transliterate(quote.textLatin, to: state.currentScript),
            source: .liveTransliteration,
            evidenceTier: nil,
            primarySourceLabel: nil
        )
    }

    func preferredRunicText(for quote: QuoteRecord) async -> String {
        await preferredRunicPresentation(for: quote).text
    }
}
