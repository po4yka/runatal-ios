//
//  QuoteCatalogUpgrade.swift
//  RunicQuotes
//
//  Created by Claude on 09.10.26.
//

import Foundation
import SwiftData

/// Corrects unchanged catalog content while preserving exact saved runes and user edits.
enum QuoteCatalogUpgrade {
    static func stage(entries: [QuoteCatalogEntry], quotes: [Quote], in context: ModelContext) throws {
        let legacy = try Dictionary(uniqueKeysWithValues: QuoteSeedCatalog.legacyIdentities().map { ($0.id, $0) })
        let current = Dictionary(uniqueKeysWithValues: entries.map { ($0.id, $0) })
        for quote in quotes {
            guard let id = quote.builtInID, let original = legacy[id], let replacement = current[id],
                  !quote.isUserGenerated, quote.textLatin == original.textLatin, quote.author == original.author,
                  quote.source == original.source else { continue }
            let hasSavedContent = quote.storedTranslationMetadataData != nil || !self.hasOnlyGeneratedGlyphs(quote)
            if quote.textLatin != replacement.textLatin && hasSavedContent {
                quote.source = "Legacy catalog wording retained with saved runic content; original attribution is not revalidated. Current catalog reference (not an exact quotation match):\n\(replacement.source ?? "Source unavailable")"
                continue
            }
            if quote.textLatin != replacement.textLatin {
                quote.textLatin = replacement.textLatin
                quote.runicElder = RunicTransliterator.transliterate(replacement.textLatin, to: .elder).glyphOutput
                quote.runicYounger = RunicTransliterator.transliterate(replacement.textLatin, to: .younger).glyphOutput
                quote.runicCirth = RunicTransliterator.transliterate(replacement.textLatin, to: .cirth).glyphOutput
                quote.translationBackfillSignature = nil
                quote.translationBackfillSourceText = nil
                try SwiftDataTranslationRepository.stageDeletion(for: quote.id, in: context)
            }
            quote.author = replacement.author
            quote.source = replacement.source
            // Preserve the user's shelf, visibility, archive status, UUID and bookmarks.
        }
    }

    private static func hasOnlyGeneratedGlyphs(_ quote: Quote) -> Bool {
        RunicScript.allCases.allSatisfy { script in
            guard let stored = quote.runicText(for: script) else { return true }
            return stored == RunicTransliterator.transliterate(quote.textLatin, to: script).glyphOutput
        }
    }
}
