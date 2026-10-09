//
//  TransliterationWarningTests.swift
//  RunicQuotes
//
//  Created by Claude on 09.10.26.
//

import Foundation
@testable import RunicQuotes
import XCTest

final class TransliterationWarningTests: XCTestCase {
    @MainActor
    func testQuoteEditorKeepsUnsupportedTextAndShowsWarnings() throws {
        let context = try TestSupport.makeModelContext()
        let viewModel = CreateEditQuoteViewModel(quoteRepository: SwiftDataQuoteRepository(modelContext: context))
        viewModel.updateQuoteText("café ВОЛК")
        XCTAssertEqual(viewModel.state.runicPreview, "ᚲᚨᚠᛖ ВОЛК")
        XCTAssertFalse(viewModel.state.transliterationWarnings.isEmpty)
        viewModel.updateQuoteText("")
        XCTAssertTrue(viewModel.state.transliterationWarnings.isEmpty)
    }

    @MainActor
    func testTranslationComposerKeepsUnsupportedTextAndShowsWarnings() throws {
        let context = try TestSupport.makeModelContext()
        let viewModel = TranslationViewModel(
            quoteRepository: SwiftDataQuoteRepository(modelContext: context),
            preferencesRepository: SwiftDataUserPreferencesRepository(modelContext: context),
        )
        viewModel.updateInputText("café ВОЛК")
        XCTAssertTrue(viewModel.state.outputText.contains("ВОЛК"))
        XCTAssertFalse(viewModel.state.userFacingWarnings.isEmpty)
    }
}
