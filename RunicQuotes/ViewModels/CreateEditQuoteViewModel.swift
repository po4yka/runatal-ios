//
//  CreateEditQuoteViewModel.swift
//  RunicQuotes
//
//  Created by Claude on 12.03.26.
//

import Foundation
import os
import SwiftData
import SwiftUI

// MARK: - UI State

struct CreateEditQuoteUiState {
    var quoteText: String = ""
    var author: String = ""
    var source: String = ""
    var collection: QuoteCollection = .motivation
    var runicPreview: String = ""
    var isSaving: Bool = false
    var errorMessage: String?
    var showSuccess: Bool = false
    var createdQuoteID: UUID?
}

// MARK: - Mode

enum CreateEditMode {
    case create
    case edit(QuoteRecord)

    var navigationTitle: String {
        switch self {
        case .create: "New Quote"
        case .edit: "Edit Quote"
        }
    }

    var saveButtonTitle: String {
        switch self {
        case .create: "Save"
        case .edit: "Done"
        }
    }
}

// MARK: - Validation

struct QuoteFormValidation {
    var quoteTextError: String?
    var authorError: String?

    var isValid: Bool {
        self.quoteTextError == nil && self.authorError == nil
    }
}

// MARK: - ViewModel

@MainActor
final class CreateEditQuoteViewModel: ObservableObject {
    // MARK: - Published State

    @Published private(set) var state = CreateEditQuoteUiState()
    @Published private(set) var validation = QuoteFormValidation()

    // MARK: - Dependencies

    let mode: CreateEditMode
    private let quoteRepository: QuoteRepository
    private let logger = Logger(subsystem: AppConstants.loggingSubsystem, category: "CreateEditQuote")

    // MARK: - Initialization

    init(quoteRepository: QuoteRepository, mode: CreateEditMode = .create) {
        self.quoteRepository = quoteRepository
        self.mode = mode

        if case .edit(let record) = mode {
            self.state.quoteText = record.textLatin
            self.state.author = record.author
            self.state.source = record.source ?? ""
            self.state.collection = record.collection
            self.updateRunicPreview()
        }
    }

    // MARK: - Form Updates

    func updateQuoteText(_ text: String) {
        self.state.quoteText = text
        if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            self.validation.quoteTextError = nil
        }
        self.updateRunicPreview()
    }

    func updateAuthor(_ author: String) {
        self.state.author = author
        if !author.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            self.validation.authorError = nil
        }
    }

    func updateSource(_ source: String) {
        self.state.source = source
    }

    func updateCollection(_ collection: QuoteCollection) {
        self.state.collection = collection
    }

    // MARK: - Validation

    func validate() -> Bool {
        var newValidation = QuoteFormValidation()

        if self.state.quoteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            newValidation.quoteTextError = "Quote text is required"
        }

        if self.state.author.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            newValidation.authorError = "Author name is required"
        }

        self.validation = newValidation
        return newValidation.isValid
    }

    // MARK: - Save

    func save() {
        guard self.validate() else { return }

        self.state.isSaving = true
        self.state.errorMessage = nil

        let trimmedText = self.state.quoteText.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAuthor = self.state.author.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedSource = self.state.source.trimmingCharacters(in: .whitespacesAndNewlines)
        let source: String? = trimmedSource.isEmpty ? nil : trimmedSource

        do {
            switch self.mode {
            case .create:
                let record = try quoteRepository.createQuote(
                    textLatin: trimmedText,
                    author: trimmedAuthor,
                    source: source,
                    collection: self.state.collection,
                    storedRunic: self.makeStoredRunicBundle(for: trimmedText),
                )
                self.state.createdQuoteID = record.id
                self.logger.info("Quote created: \(record.id)")

            case .edit(let existing):
                _ = try self.quoteRepository.updateQuote(
                    id: existing.id,
                    textLatin: trimmedText,
                    author: trimmedAuthor,
                    source: source,
                    collection: self.state.collection,
                    storedRunic: self.makeStoredRunicBundle(for: trimmedText),
                )
                self.logger.info("Quote updated: \(existing.id)")
            }

            self.state.isSaving = false
            self.state.showSuccess = true
        } catch {
            self.state.isSaving = false
            self.state.errorMessage = error.localizedDescription
            self.logger.error("Save failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Reset for Create Another

    func resetForNewQuote() {
        self.state = CreateEditQuoteUiState()
        self.validation = QuoteFormValidation()
    }

    // MARK: - Preview

    static func preview(mode: CreateEditMode = .create) -> CreateEditQuoteViewModel {
        let container = ModelContainerHelper.createPlaceholderContainer()
        return CreateEditQuoteViewModel(
            quoteRepository: SwiftDataQuoteRepository(modelContext: ModelContext(container)),
            mode: mode,
        )
    }

    // MARK: - Private

    private func updateRunicPreview() {
        let text = self.state.quoteText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            self.state.runicPreview = ""
            return
        }
        self.state.runicPreview = RunicTransliterator.transliterate(text, to: .elder)
    }

    private func makeStoredRunicBundle(for text: String) -> RunicTextBundle? {
        guard !text.isEmpty else { return nil }

        return RunicTextBundle(
            elder: RunicTransliterator.transliterate(text, to: .elder),
            younger: RunicTransliterator.transliterate(text, to: .younger),
            cirth: RunicTransliterator.transliterate(text, to: .cirth),
        )
    }
}
