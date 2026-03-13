//
//  TranslationViewModelTests.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

@testable import RunicQuotes
import SwiftData
import XCTest

final class TranslationViewModelTests: XCTestCase {
    @MainActor
    func testTranslateModeProducesStructuredResult() throws {
        let (viewModel, _) = try makeViewModel()

        viewModel.onAppear()
        viewModel.selectMode(.translate)
        viewModel.selectScript(.younger)
        viewModel.updateInputText("The wolf hunts at night")

        XCTAssertEqual(viewModel.state.translationMode, .translate)
        XCTAssertEqual(viewModel.state.derivationKind, .goldExample)
        XCTAssertEqual(viewModel.state.resolutionStatus, .reconstructed)
        XCTAssertEqual(viewModel.state.supportLevel, .supported)
        XCTAssertEqual(viewModel.state.evidenceTier, .reconstructed)
        XCTAssertFalse(viewModel.state.outputText.isEmpty)
        XCTAssertFalse(viewModel.state.provenance.isEmpty)
    }

    @MainActor
    func testSaveToLibraryInTranslateModeCachesResults() throws {
        let (viewModel, context) = try makeViewModel()

        viewModel.onAppear()
        viewModel.selectMode(.translate)
        viewModel.selectScript(.younger)
        viewModel.updateInputText("The wolf hunts at night")
        viewModel.saveToLibrary()

        let quotes = try context.fetch(FetchDescriptor<Quote>())
        let quote = try XCTUnwrap(quotes.first)
        let translationRepository = SwiftDataTranslationRepository(modelContext: context)

        XCTAssertEqual(quote.author, "Runatal")
        XCTAssertTrue(viewModel.state.didSave)
        XCTAssertNotNil(try translationRepository.latestTranslation(for: quote.id, script: .younger))
    }

    @MainActor
    func testSetWordByWordEnabledUpdatesState() throws {
        let (viewModel, _) = try makeViewModel()

        viewModel.onAppear()
        viewModel.setWordByWordEnabled(true)

        XCTAssertTrue(viewModel.state.isWordByWordEnabled)

        viewModel.setWordByWordEnabled(false)

        XCTAssertFalse(viewModel.state.isWordByWordEnabled)
    }

    @MainActor
    func testUnsupportedLanguageShowsGuidance() throws {
        let (viewModel, _) = try makeViewModel()

        viewModel.onAppear()
        viewModel.selectMode(.translate)
        viewModel.updateInputText("волк ночью")

        XCTAssertEqual(viewModel.state.supportLevel, .unsupported)
        XCTAssertEqual(viewModel.state.evidenceTier, .unsupported)
        XCTAssertTrue(viewModel.state.userFacingWarnings.contains(where: { $0.contains("English input only") }))
    }

    @MainActor
    private func makeViewModel() throws -> (TranslationViewModel, ModelContext) {
        let schema = Schema([Quote.self, UserPreferences.self, TranslationRecord.self, TranslationBackfillState.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: config)
        let context = ModelContext(container)
        return (TranslationViewModel(modelContext: context), context)
    }
}
