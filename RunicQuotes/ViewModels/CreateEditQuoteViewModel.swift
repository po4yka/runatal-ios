//
//  CreateEditQuoteViewModel.swift
//  RunicQuotes
//
//  Created by Claude on 2026-03-12.
//

import Foundation
import SwiftUI
import SwiftData
import os

// MARK: - UI State

struct CreateEditQuoteUiState: Sendable {
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

enum CreateEditMode: Sendable {
    case create
    case edit(QuoteRecord)

    var navigationTitle: String {
        switch self {
        case .create: return "New Quote"
        case .edit: return "Edit Quote"
        }
    }

    var saveButtonTitle: String {
        switch self {
        case .create: return "Save"
        case .edit: return "Done"
        }
    }
}

// MARK: - Validation

struct QuoteFormValidation: Sendable {
    var quoteTextError: String?
    var authorError: String?

    var isValid: Bool {
        quoteTextError == nil && authorError == nil
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
    private var modelContext: ModelContext
    private var isConfiguredWithEnvironmentContext = false
    private let logger = Logger(subsystem: AppConstants.loggingSubsystem, category: "CreateEditQuote")

    // MARK: - Initialization

    init(modelContext: ModelContext, mode: CreateEditMode = .create) {
        self.modelContext = modelContext
        self.mode = mode

        if case .edit(let record) = mode {
            state.quoteText = record.textLatin
            state.author = record.author
            state.source = record.source ?? ""
            state.collection = record.collection
            updateRunicPreview()
        }
    }

    /// Rebind to the environment-provided ModelContext once mounted.
    func configureIfNeeded(modelContext: ModelContext) {
        guard !isConfiguredWithEnvironmentContext else { return }
        self.modelContext = modelContext
        isConfiguredWithEnvironmentContext = true
    }

    // MARK: - Form Updates

    func updateQuoteText(_ text: String) {
        state.quoteText = text
        if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validation.quoteTextError = nil
        }
        updateRunicPreview()
    }

    func updateAuthor(_ author: String) {
        state.author = author
        if !author.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validation.authorError = nil
        }
    }

    func updateSource(_ source: String) {
        state.source = source
    }

    func updateCollection(_ collection: QuoteCollection) {
        state.collection = collection
    }

    // MARK: - Validation

    func validate() -> Bool {
        var newValidation = QuoteFormValidation()

        if state.quoteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            newValidation.quoteTextError = "Quote text is required"
        }

        if state.author.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            newValidation.authorError = "Author name is required"
        }

        validation = newValidation
        return newValidation.isValid
    }

    // MARK: - Save

    func save() {
        guard validate() else { return }

        state.isSaving = true
        state.errorMessage = nil

        let repository = SwiftDataQuoteRepository(modelContext: modelContext)
        let trimmedText = state.quoteText.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAuthor = state.author.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedSource = state.source.trimmingCharacters(in: .whitespacesAndNewlines)
        let source: String? = trimmedSource.isEmpty ? nil : trimmedSource

        do {
            switch mode {
            case .create:
                let record = try repository.createQuote(
                    textLatin: trimmedText,
                    author: trimmedAuthor,
                    source: source,
                    collection: state.collection
                )
                state.createdQuoteID = record.id
                logger.info("Quote created: \(record.id)")

            case .edit(let existing):
                _ = try repository.updateQuote(
                    id: existing.id,
                    textLatin: trimmedText,
                    author: trimmedAuthor,
                    source: source,
                    collection: state.collection
                )
                logger.info("Quote updated: \(existing.id)")
            }

            state.isSaving = false
            state.showSuccess = true
        } catch {
            state.isSaving = false
            state.errorMessage = error.localizedDescription
            logger.error("Save failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Reset for Create Another

    func resetForNewQuote() {
        state = CreateEditQuoteUiState()
        validation = QuoteFormValidation()
    }

    // MARK: - Preview

    static func preview(mode: CreateEditMode = .create) -> CreateEditQuoteViewModel {
        let container = ModelContainerHelper.createPlaceholderContainer()
        return CreateEditQuoteViewModel(
            modelContext: ModelContext(container),
            mode: mode
        )
    }

    // MARK: - Private

    private func updateRunicPreview() {
        let text = state.quoteText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            state.runicPreview = ""
            return
        }
        state.runicPreview = RunicTransliterator.transliterate(text, to: .elder)
    }
}
