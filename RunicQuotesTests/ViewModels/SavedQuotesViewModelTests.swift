//
//  SavedQuotesViewModelTests.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import Foundation
@testable import RunicQuotes
import Testing

@MainActor
@Suite(.serialized, .tags(.viewModel))
struct SavedQuotesViewModelTests {
    @Test
    func onAppearLoadsSavedQuotesFromSnapshot() async {
        let savedQuote = TestSupport.makeQuoteRecord(text: "The hidden road", author: "Tolkien")
        let repository = TestQuoteRepository()
        repository.allQuotesValue = [savedQuote, TestSupport.makeQuoteRecord(text: "Other", author: "Virgil")]

        let preferences = TestPreferencesRepository()
        var snapshot = UserPreferencesSnapshot()
        snapshot.savedQuoteIDs = [savedQuote.id]
        preferences.snapshotResult = .success(snapshot)

        let viewModel = SavedQuotesViewModel(
            quoteProvider: QuoteProvider(repository: repository),
            preferencesRepository: preferences,
        )

        viewModel.onAppear()

        #expect(await TestSupport.eventually { !viewModel.state.isLoading })
        #expect(viewModel.state.savedQuotes.map(\.id) == [savedQuote.id])
        #expect(viewModel.savedCount == 1)
    }

    @Test
    func toggleSavedPersistsAndRemovesQuoteLocally() async {
        let savedQuote = TestSupport.makeQuoteRecord()
        let repository = TestQuoteRepository()
        repository.allQuotesValue = [savedQuote]
        let preferences = TestPreferencesRepository()
        var snapshot = UserPreferencesSnapshot()
        snapshot.savedQuoteIDs = [savedQuote.id]
        preferences.snapshotResult = .success(snapshot)

        let viewModel = SavedQuotesViewModel(
            quoteProvider: QuoteProvider(repository: repository),
            preferencesRepository: preferences,
        )
        viewModel.onAppear()
        #expect(await TestSupport.eventually { !viewModel.state.isLoading })

        viewModel.toggleSaved(savedQuote.id)

        #expect(await TestSupport.eventually { viewModel.state.savedQuotes.isEmpty })
        #expect(preferences.saveCalls.count >= 1)
        #expect(preferences.saveCalls.last?.savedQuoteIDs.contains(savedQuote.id) == false)
    }

    @Test
    func toggleSavedSurfacesPersistenceErrors() async {
        let savedQuote = TestSupport.makeQuoteRecord()
        let repository = TestQuoteRepository()
        repository.allQuotesValue = [savedQuote]
        let preferences = TestPreferencesRepository()
        var snapshot = UserPreferencesSnapshot()
        snapshot.savedQuoteIDs = [savedQuote.id]
        preferences.snapshotResult = .success(snapshot)
        preferences.saveResult = .failure(TestError(message: "save failed"))

        let viewModel = SavedQuotesViewModel(
            quoteProvider: QuoteProvider(repository: repository),
            preferencesRepository: preferences,
        )
        viewModel.onAppear()
        #expect(await TestSupport.eventually { !viewModel.state.isLoading })

        viewModel.toggleSaved(savedQuote.id)

        #expect(viewModel.state.errorMessage == "Failed to save changes: save failed")
    }

    @Test
    func copyQuoteTextFormatsForSharing() {
        let quote = TestSupport.makeQuoteRecord(text: "Fortune favors the bold", author: "Virgil")
        let viewModel = SavedQuotesViewModel(
            quoteProvider: QuoteProvider(repository: TestQuoteRepository()),
            preferencesRepository: TestPreferencesRepository(),
        )

        #expect(viewModel.copyQuoteText(quote) == "\"Fortune favors the bold\" -- Virgil")
    }

    @Test
    func onAppearSurfacesLoadErrors() async {
        let repository = TestQuoteRepository()
        repository.allQuotesError = TestError(message: "quotes failed")
        let preferences = TestPreferencesRepository()
        preferences.snapshotResult = .success(UserPreferencesSnapshot())

        let viewModel = SavedQuotesViewModel(
            quoteProvider: QuoteProvider(repository: repository),
            preferencesRepository: preferences,
        )

        viewModel.onAppear()

        #expect(await TestSupport.eventually {
            !viewModel.state.isLoading && viewModel.state.errorMessage != nil
        })
        #expect(viewModel.state.errorMessage == "Failed to load saved quotes: quotes failed")
    }
}
