//
//  TranslationViewModelTests.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import SwiftData
import Testing
@testable import RunicQuotes

@MainActor
@Suite(.serialized, .tags(.viewModel))
struct TranslationViewModelTests {
    @Test
    func translateModeProducesStructuredResult() throws {
        let (viewModel, _) = try makeViewModel()

        viewModel.onAppear()
        viewModel.selectMode(.translate)
        viewModel.selectScript(.younger)
        viewModel.updateInputText("The wolf hunts at night")

        #expect(viewModel.state.translationMode == .translate)
        #expect(viewModel.state.derivationKind == .goldExample)
        #expect(viewModel.state.resolutionStatus == .reconstructed)
        #expect(viewModel.state.supportLevel == .supported)
        #expect(viewModel.state.evidenceTier == .reconstructed)
        #expect(!viewModel.state.outputText.isEmpty)
        #expect(!viewModel.state.provenance.isEmpty)
    }

    @Test
    func saveToLibraryInTranslateModeCachesResults() throws {
        let (viewModel, context) = try makeViewModel()

        viewModel.onAppear()
        viewModel.selectMode(.translate)
        viewModel.selectScript(.younger)
        viewModel.updateInputText("The wolf hunts at night")
        viewModel.saveToLibrary()

        let quotes = try context.fetch(FetchDescriptor<Quote>())
        let quote = try #require(quotes.first)
        let translationRepository = SwiftDataTranslationRepository(modelContext: context)

        #expect(quote.author == "Runatal")
        #expect(viewModel.state.didSave)
        #expect(try translationRepository.latestTranslation(for: quote.id, script: .younger) != nil)
    }

    @Test
    func setWordByWordEnabledUpdatesState() throws {
        let (viewModel, _) = try makeViewModel()

        viewModel.onAppear()
        viewModel.setWordByWordEnabled(true)
        #expect(viewModel.state.isWordByWordEnabled)

        viewModel.setWordByWordEnabled(false)
        #expect(!viewModel.state.isWordByWordEnabled)
    }

    @Test
    func unsupportedLanguageShowsGuidance() throws {
        let (viewModel, _) = try makeViewModel()

        viewModel.onAppear()
        viewModel.selectMode(.translate)
        viewModel.updateInputText("волк ночью")

        #expect(viewModel.state.supportLevel == .unsupported)
        #expect(viewModel.state.evidenceTier == .unsupported)
        #expect(viewModel.state.userFacingWarnings.contains { $0.contains("English input only") })
    }

    private func makeViewModel() throws -> (TranslationViewModel, ModelContext) {
        let context = try TestSupport.makeModelContext()
        return (TranslationViewModel(modelContext: context), context)
    }
}
