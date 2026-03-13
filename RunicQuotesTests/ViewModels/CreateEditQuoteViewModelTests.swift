//
//  CreateEditQuoteViewModelTests.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

@testable import RunicQuotes
import Testing

@MainActor
@Suite(.serialized, .tags(.viewModel))
struct CreateEditQuoteViewModelTests {
    @Test
    func createModeStartsEmpty() {
        let viewModel = CreateEditQuoteViewModel(quoteRepository: TestQuoteRepository())

        #expect(viewModel.mode.navigationTitle == "New Quote")
        #expect(viewModel.state.quoteText.isEmpty)
        #expect(viewModel.state.author.isEmpty)
        #expect(viewModel.state.runicPreview.isEmpty)
        #expect(viewModel.validation.isValid)
    }

    @Test
    func editModePreloadsExistingRecord() {
        let record = TestSupport.makeQuoteRecord(
            text: "Fortune favors the bold",
            author: "Virgil",
            source: "Aeneid",
            collection: .stoic,
        )
        let viewModel = CreateEditQuoteViewModel(
            quoteRepository: TestQuoteRepository(),
            mode: .edit(record),
        )

        #expect(viewModel.mode.navigationTitle == "Edit Quote")
        #expect(viewModel.state.quoteText == "Fortune favors the bold")
        #expect(viewModel.state.author == "Virgil")
        #expect(viewModel.state.source == "Aeneid")
        #expect(viewModel.state.collection == .stoic)
        #expect(!viewModel.state.runicPreview.isEmpty)
    }

    @Test
    func updateQuoteTextRefreshesPreviewAndClearsError() {
        let viewModel = CreateEditQuoteViewModel(quoteRepository: TestQuoteRepository())
        _ = viewModel.validate()

        viewModel.updateQuoteText("The wolf hunts at night")

        #expect(viewModel.validation.quoteTextError == nil)
        #expect(!viewModel.state.runicPreview.isEmpty)
    }

    @Test
    func validateRequiresQuoteAndAuthor() {
        let viewModel = CreateEditQuoteViewModel(quoteRepository: TestQuoteRepository())

        #expect(!viewModel.validate())
        #expect(viewModel.validation.quoteTextError == "Quote text is required")
        #expect(viewModel.validation.authorError == "Author name is required")
    }

    @Test
    func saveCreatesQuoteAndTracksSuccess() {
        let repository = TestQuoteRepository()
        let viewModel = CreateEditQuoteViewModel(quoteRepository: repository)

        viewModel.updateQuoteText("The wolf hunts at night")
        viewModel.updateAuthor("Runatal")
        viewModel.updateSource("Saga")
        viewModel.updateCollection(.stoic)
        viewModel.save()

        #expect(repository.createdQuotes.count == 1)
        #expect(viewModel.state.isSaving == false)
        #expect(viewModel.state.showSuccess)
        #expect(viewModel.state.createdQuoteID == repository.createdQuotes.first?.id)
        #expect(repository.createdQuotes.first?.collection == .stoic)
    }

    @Test
    func saveUpdatesExistingQuoteInEditMode() {
        let record = TestSupport.makeQuoteRecord(text: "Old", author: "Author")
        let repository = TestQuoteRepository()
        let viewModel = CreateEditQuoteViewModel(
            quoteRepository: repository,
            mode: .edit(record),
        )

        viewModel.updateQuoteText("New quote")
        viewModel.updateAuthor("New author")
        viewModel.save()

        #expect(repository.updatedQuotes.count == 1)
        #expect(repository.updatedQuotes.first?.id == record.id)
        #expect(viewModel.state.createdQuoteID == nil)
        #expect(viewModel.state.showSuccess)
    }

    @Test
    func saveSurfacesRepositoryErrors() {
        let repository = TestQuoteRepository()
        repository.createError = TestError(message: "save failed")
        let viewModel = CreateEditQuoteViewModel(quoteRepository: repository)

        viewModel.updateQuoteText("The wolf hunts at night")
        viewModel.updateAuthor("Runatal")
        viewModel.save()

        #expect(viewModel.state.errorMessage == "save failed")
        #expect(viewModel.state.isSaving == false)
        #expect(viewModel.state.showSuccess == false)
    }

    @Test
    func resetForNewQuoteRestoresInitialState() {
        let repository = TestQuoteRepository()
        let viewModel = CreateEditQuoteViewModel(quoteRepository: repository)
        viewModel.updateQuoteText("The wolf hunts at night")
        viewModel.updateAuthor("Runatal")
        viewModel.save()

        viewModel.resetForNewQuote()

        #expect(viewModel.state.quoteText.isEmpty)
        #expect(viewModel.state.author.isEmpty)
        #expect(viewModel.state.runicPreview.isEmpty)
        #expect(viewModel.state.showSuccess == false)
        #expect(viewModel.validation.isValid)
    }
}
