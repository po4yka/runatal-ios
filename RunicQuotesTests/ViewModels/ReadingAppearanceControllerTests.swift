//
//  ReadingAppearanceControllerTests.swift
//  RunicQuotes
//
//  Created by Claude on 09.10.26.
//

import Foundation
@testable import RunicQuotes
import SwiftData
import Testing

@MainActor
@Suite(.serialized, .tags(.viewModel))
struct ReadingAppearanceControllerTests {
    @Test
    func nativeLibraryUsesCurrentSelectedScriptAndPreservesNewExactOutput() async throws {
        let context = try TestSupport.makeModelContext()
        let quotes = SwiftDataQuoteRepository(modelContext: context)
        let text = "The wolf hunts at night"
        let quote = try quotes.createQuote(textLatin: text, author: "Reader", source: nil, collection: .stoic)
        let result = HistoricalTranslationService().translate(text: text, script: .younger, fidelity: .strict)
        #expect(result.isAvailable)
        try SwiftDataTranslationRepository(modelContext: context).cache(result: result, for: quote.id, sourceText: text)
        let preferences = SwiftDataUserPreferencesRepository(modelContext: context)
        try preferences.apply([.script(.younger)])
        let model = ReadingAppearanceController(repository: preferences, quotes: QuoteProvider(modelContainer: context.container), translations: TranslationProvider(modelContainer: context.container))
        #expect(await TestSupport.eventually { model.script == .younger && model.presentation(for: quote).text == result.glyphOutput })
        #expect(model.font.isCompatible(with: .younger))
        let edited = try quotes.updateQuote(id: quote.id, textLatin: text, author: "Reader", source: nil, collection: .stoic, storedRunic: RunicTextBundle(elder: nil, younger: "EXACT SAVED OUTPUT", cirth: nil))
        // The new record invalidates the cached presentation immediately, before its event reload.
        #expect(model.presentation(for: edited).text == "EXACT SAVED OUTPUT")
        #expect(model.presentation(for: edited).source == .savedRunicText)
    }

    @Test
    func originalPassageSourceAcceptsOnlyExplicitWebLinks() {
        #expect(QuoteSourceSheet.webURL(in: "Work, edition, stanza 1\nhttps://example.org/source")?.host == "example.org")
        #expect(QuoteSourceSheet.webURL(in: "file:///private/example") == nil)
        #expect(QuoteSourceSheet.webURL(in: "javascript:alert(1)") == nil)
        #expect(QuoteSourceSheet.webURL(in: "Original work without a link") == nil)
    }
}
