//
//  TranslationViewModel.swift
//  RunicQuotes
//
//  Created by Codex on 2026-03-13.
//

import Foundation
import SwiftData
import SwiftUI
import os

private let translationMaxInputLength = 280

struct TranslationUiState: Sendable {
    var inputText: String = ""
    var selectedScript: RunicScript = .elder
    var selectedFont: RunicFont = .noto
    var translationMode: TranslationMode = .default
    var selectedFidelity: TranslationFidelity = .default
    var selectedYoungerVariant: YoungerFutharkVariant = .default
    var outputText: String = ""
    var normalizedForm: String?
    var diplomaticForm: String?
    var resolutionStatus: TranslationResolutionStatus?
    var derivationKind: TranslationDerivationKind?
    var notes: [String] = []
    var provenance: [TranslationProvenanceEntry] = []
    var tokenBreakdown: [TranslationTokenBreakdown] = []
    var unresolvedTokens: [String] = []
    var isWordByWordEnabled = false
    var isSaving = false
    var errorMessage: String?
    var successMessage: String?
    var didSave = false

    var remainingCharacters: Int {
        max(0, translationMaxInputLength - inputText.count)
    }

    var isInputEmpty: Bool {
        inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var fallbackSuggestion: String? {
        guard translationMode == .translate else { return nil }
        guard resolutionStatus == .unavailable else { return nil }
        if selectedFidelity == .strict {
            return "Try Readable or Decorative to allow approximated output."
        }
        return "This phrase has gaps in the curated dataset for the selected script."
    }
}

@MainActor
final class TranslationViewModel: ObservableObject {
    @Published private(set) var state = TranslationUiState()

    private var modelContext: ModelContext
    private var isConfiguredWithEnvironmentContext = false
    private var preferences: UserPreferences?
    private let translationService: HistoricalTranslationService
    private let logger = Logger(subsystem: AppConstants.loggingSubsystem, category: "Translation")

    init(
        modelContext: ModelContext,
        translationService: HistoricalTranslationService = HistoricalTranslationService()
    ) {
        self.modelContext = modelContext
        self.translationService = translationService
    }

    func configureIfNeeded(modelContext: ModelContext) {
        guard !isConfiguredWithEnvironmentContext else { return }
        self.modelContext = modelContext
        isConfiguredWithEnvironmentContext = true
    }

    func onAppear() {
        loadPreferences()
        rebuildPresentation()
    }

    func updateInputText(_ text: String) {
        state.inputText = String(text.prefix(translationMaxInputLength))
        state.errorMessage = nil
        state.successMessage = nil
        rebuildPresentation()
    }

    func selectMode(_ mode: TranslationMode) {
        state.translationMode = mode
        state.errorMessage = nil
        state.successMessage = nil
        rebuildPresentation()
    }

    func selectScript(_ script: RunicScript) {
        state.selectedScript = script
        if !state.selectedFont.isCompatible(with: script) {
            state.selectedFont = RunicFontConfiguration.recommendedFont(for: script)
        }
        preferences?.selectedScript = script
        preferences?.selectedFont = state.selectedFont
        persistPreferences()
        rebuildPresentation()
    }

    func selectFidelity(_ fidelity: TranslationFidelity) {
        state.selectedFidelity = fidelity
        rebuildPresentation()
    }

    func selectYoungerVariant(_ variant: YoungerFutharkVariant) {
        state.selectedYoungerVariant = variant
        rebuildPresentation()
    }

    func clearInput() {
        state.inputText = ""
        state.outputText = ""
        state.normalizedForm = nil
        state.diplomaticForm = nil
        state.notes = []
        state.provenance = []
        state.tokenBreakdown = []
        state.unresolvedTokens = []
        state.resolutionStatus = nil
        state.derivationKind = nil
        state.errorMessage = nil
        state.successMessage = nil
        state.didSave = false
    }

    func toggleWordByWordMode() {
        state.isWordByWordEnabled.toggle()
    }

    func saveToLibrary() {
        let input = state.inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else {
            state.errorMessage = "Enter a phrase to save."
            return
        }

        state.isSaving = true
        state.errorMessage = nil
        state.successMessage = nil
        state.didSave = false

        do {
            let quoteRepository = SwiftDataQuoteRepository(modelContext: modelContext)
            let translationRepository = SwiftDataTranslationRepository(
                modelContext: modelContext,
                translationService: translationService
            )

            let savedQuote: QuoteRecord
            let saveMessage: String
            switch state.translationMode {
            case .transliterate:
                (savedQuote, saveMessage) = try saveTransliterationQuote(
                    input: input,
                    quoteRepository: quoteRepository
                )

            case .translate:
                (savedQuote, saveMessage) = try saveStructuredQuote(
                    input: input,
                    quoteRepository: quoteRepository,
                    translationRepository: translationRepository
                )
            }

            logger.info("Saved translation flow quote: \(savedQuote.id)")
            state.isSaving = false
            state.successMessage = saveMessage
            state.didSave = true
        } catch {
            state.isSaving = false
            state.errorMessage = error.localizedDescription
            logger.error("Failed to save translation flow quote: \(error.localizedDescription)")
        }
    }

    static func preview() -> TranslationViewModel {
        let container = ModelContainerHelper.createPlaceholderContainer()
        return TranslationViewModel(modelContext: ModelContext(container))
    }

    private func loadPreferences() {
        do {
            let preferences = try UserPreferences.getOrCreate(in: modelContext)
            self.preferences = preferences
            state.selectedScript = preferences.selectedScript
            state.selectedFont = preferences.selectedFont.isCompatible(with: preferences.selectedScript)
                ? preferences.selectedFont
                : RunicFontConfiguration.recommendedFont(for: preferences.selectedScript)
        } catch {
            state.errorMessage = "Failed to load preferences: \(error.localizedDescription)"
        }
    }

    private func persistPreferences() {
        do {
            try modelContext.save()
        } catch {
            state.errorMessage = "Failed to save preferences: \(error.localizedDescription)"
        }
    }

    private func rebuildPresentation() {
        let input = state.inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else {
            state.outputText = ""
            state.normalizedForm = nil
            state.diplomaticForm = nil
            state.resolutionStatus = nil
            state.derivationKind = nil
            state.notes = []
            state.provenance = []
            state.tokenBreakdown = []
            state.unresolvedTokens = []
            return
        }

        switch state.translationMode {
        case .transliterate:
            state.outputText = RunicTransliterator.transliterate(input, to: state.selectedScript)
            state.normalizedForm = nil
            state.diplomaticForm = nil
            state.resolutionStatus = nil
            state.derivationKind = nil
            state.notes = []
            state.provenance = []
            state.unresolvedTokens = []
            state.tokenBreakdown = buildTransliterationBreakdown(for: input, script: state.selectedScript)

        case .translate:
            let result = translationService.translate(
                text: input,
                script: state.selectedScript,
                fidelity: state.selectedFidelity,
                youngerVariant: state.selectedYoungerVariant
            )
            state.outputText = result.glyphOutput
            state.normalizedForm = result.normalizedForm.nilIfEmpty
            state.diplomaticForm = result.diplomaticForm.nilIfEmpty
            state.resolutionStatus = result.resolutionStatus
            state.derivationKind = result.derivationKind
            state.notes = result.notes
            state.provenance = result.provenance
            state.tokenBreakdown = result.tokenBreakdown
            state.unresolvedTokens = result.unresolvedTokens
        }
    }

    private func buildTransliterationBreakdown(
        for text: String,
        script: RunicScript
    ) -> [TranslationTokenBreakdown] {
        text
            .split(whereSeparator: \.isWhitespace)
            .map(String.init)
            .map { token in
                TranslationTokenBreakdown(
                    sourceToken: token,
                    normalizedToken: token.lowercased(),
                    diplomaticToken: token.lowercased(),
                    glyphToken: RunicTransliterator.transliterate(token, to: script),
                    resolutionStatus: .reconstructed,
                    provenance: []
                )
            }
    }

    private func saveTransliterationQuote(
        input: String,
        quoteRepository: SwiftDataQuoteRepository
    ) throws -> (QuoteRecord, String) {
        let bundle = RunicTextBundle(
            elder: RunicTransliterator.transliterate(input, to: .elder),
            younger: RunicTransliterator.transliterate(input, to: .younger),
            cirth: RunicTransliterator.transliterate(input, to: .cirth)
        )
        let savedQuote = try quoteRepository.createQuote(
            textLatin: input,
            author: "Runatal",
            source: nil,
            collection: .motivation,
            storedRunic: bundle
        )
        return (savedQuote, String(localized: "translation.save.success"))
    }

    private func saveStructuredQuote(
        input: String,
        quoteRepository: SwiftDataQuoteRepository,
        translationRepository: SwiftDataTranslationRepository
    ) throws -> (QuoteRecord, String) {
        let results = translationService.translateAllAvailable(
            text: input,
            fidelity: state.selectedFidelity,
            youngerVariant: state.selectedYoungerVariant
        )
        let bundle = RunicTextBundle(
            elder: results.first(where: { $0.script == .elder && $0.isAvailable })?.glyphOutput,
            younger: results.first(where: { $0.script == .younger && $0.isAvailable })?.glyphOutput,
            cirth: results.first(where: { $0.script == .cirth && $0.isAvailable })?.glyphOutput
        )
        let savedQuote = try quoteRepository.createQuote(
            textLatin: input,
            author: "Runatal",
            source: nil,
            collection: .motivation,
            storedRunic: bundle
        )
        try translationRepository.cache(results: results, for: savedQuote.id, sourceText: input)
        return (savedQuote, String(localized: "translation.save.success.structured"))
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
