//
//  InputLengthBoundaryTests.swift
//  RunicQuotes
//
//  Created by Claude on 09.10.26.
//

import Foundation
@testable import RunicQuotes
import Testing

@MainActor
@Suite(.serialized, .tags(.viewModel))
struct InputLengthBoundaryTests {
    @Test
    func studioPreservesOversizedInputAndNeverSavesItsTruncatedPrefix() throws {
        let context = try TestSupport.makeModelContext()
        let quotes = SwiftDataQuoteRepository(modelContext: context)
        let model = TranslationViewModel(quoteRepository: quotes, preferencesRepository: SwiftDataUserPreferencesRepository(modelContext: context))
        let text = String(repeating: "a", count: AppConstants.maxQuoteLength + 1)
        model.updateInputText(text)
        #expect(model.state.inputText == text)
        #expect(model.state.outputText.isEmpty)
        #expect(model.state.errorMessage != nil)
        #expect(!model.state.canSave)
        model.saveToLibrary()
        #expect(!model.state.didSave)
        #expect(try quotes.allQuotes().isEmpty)
        model.updateInputText("A complete passage after the oversized input")
        #expect(model.state.errorMessage == nil)
        #expect(!model.state.outputText.isEmpty)
        model.saveToLibrary()
        #expect(model.state.didSave)
        #expect(try quotes.allQuotes().first?.textLatin == model.state.inputText)
    }

    @Test
    func editorPreservesOversizedInputAndRejectsItBeforePreviewAndInsertion() throws {
        let context = try TestSupport.makeModelContext()
        let quotes = SwiftDataQuoteRepository(modelContext: context)
        let model = CreateEditQuoteViewModel(quoteRepository: quotes)
        let text = String(repeating: "a", count: AppConstants.maxQuoteLength + 1)
        model.updateQuoteText(text)
        model.updateAuthor("Reader")
        model.save()
        #expect(model.state.quoteText == text)
        #expect(model.state.runicPreview.isEmpty)
        #expect(model.validation.quoteTextError != nil)
        #expect(!model.state.showSuccess)
        #expect(try quotes.allQuotes().isEmpty)
    }
}
