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
    var supportLevel: TranslationSupportLevel?
    var evidenceTier: TranslationEvidenceTier?
    var derivationKind: TranslationDerivationKind?
    var notes: [String] = []
    var provenance: [TranslationProvenanceEntry] = []
    var tokenBreakdown: [TranslationTokenBreakdown] = []
    var unresolvedTokens: [String] = []
    var attestationRefs: [String] = []
    var inputLanguage: TranslationSourceLanguage = .english
    var userFacingWarnings: [String] = []
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

    var sourceLanguageBanner: String? {
        guard translationMode == .translate else { return nil }
        return "Historical translation currently supports English input only."
    }

    var primarySourceLabel: String? {
        provenance.first?.label
    }

    var primarySourceDetail: String? {
        provenance.first?.detail ?? provenance.first?.sourceWork
    }
}

@MainActor
final class TranslationViewModel: ObservableObject {
    @Published private(set) var state = TranslationUiState()

    private let quoteRepository: QuoteRepository
    private let translationRepository: TranslationRepository
    private let preferencesRepository: any UserPreferencesRepository
    private var preferences = UserPreferencesSnapshot()
    private let translationService: HistoricalTranslationService
    private let logger = Logger(subsystem: AppConstants.loggingSubsystem, category: "Translation")

    init(
        quoteRepository: QuoteRepository,
        translationRepository: TranslationRepository,
        preferencesRepository: any UserPreferencesRepository,
        translationService: HistoricalTranslationService = HistoricalTranslationService()
    ) {
        self.quoteRepository = quoteRepository
        self.translationRepository = translationRepository
        self.preferencesRepository = preferencesRepository
        self.translationService = translationService
    }

    convenience init(
        modelContext: ModelContext,
        translationService: HistoricalTranslationService = HistoricalTranslationService()
    ) {
        let translationRepository = SwiftDataTranslationRepository(
            modelContext: modelContext,
            translationService: translationService
        )
        self.init(
            quoteRepository: SwiftDataQuoteRepository(
                modelContext: modelContext,
                translationCacheRepository: translationRepository
            ),
            translationRepository: translationRepository,
            preferencesRepository: SwiftDataUserPreferencesRepository(modelContext: modelContext),
            translationService: translationService
        )
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
        preferences.selectedScript = script
        preferences.selectedFont = state.selectedFont
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
        state.attestationRefs = []
        state.inputLanguage = .english
        state.userFacingWarnings = []
        state.resolutionStatus = nil
        state.supportLevel = nil
        state.evidenceTier = nil
        state.derivationKind = nil
        state.errorMessage = nil
        state.successMessage = nil
        state.didSave = false
    }

    func toggleWordByWordMode() {
        state.isWordByWordEnabled.toggle()
    }

    func setWordByWordEnabled(_ enabled: Bool) {
        state.isWordByWordEnabled = enabled
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
        let context = ModelContext(container)
        let translationRepository = SwiftDataTranslationRepository(modelContext: context)
        return TranslationViewModel(
            quoteRepository: SwiftDataQuoteRepository(
                modelContext: context,
                translationCacheRepository: translationRepository
            ),
            translationRepository: translationRepository,
            preferencesRepository: SwiftDataUserPreferencesRepository(modelContext: context)
        )
    }

    private func loadPreferences() {
        do {
            preferences = try preferencesRepository.snapshot()
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
            try preferencesRepository.save(preferences)
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
            state.supportLevel = nil
            state.evidenceTier = nil
            state.derivationKind = nil
            state.notes = []
            state.provenance = []
            state.tokenBreakdown = []
            state.unresolvedTokens = []
            state.attestationRefs = []
            state.inputLanguage = .english
            state.userFacingWarnings = []
            return
        }

        switch state.translationMode {
        case .transliterate:
            state.outputText = RunicTransliterator.transliterate(input, to: state.selectedScript)
            state.normalizedForm = nil
            state.diplomaticForm = nil
            state.resolutionStatus = nil
            state.supportLevel = nil
            state.evidenceTier = nil
            state.derivationKind = nil
            state.notes = []
            state.provenance = []
            state.unresolvedTokens = []
            state.attestationRefs = []
            state.inputLanguage = .english
            state.userFacingWarnings = []
            state.tokenBreakdown = buildTransliterationBreakdown(for: input, script: state.selectedScript)

        case .translate:
            let result = translationService.translate(
                text: input,
                script: state.selectedScript,
                fidelity: state.selectedFidelity,
                youngerVariant: state.selectedYoungerVariant,
                sourceLanguage: .english
            )
            state.outputText = result.glyphOutput
            state.normalizedForm = result.normalizedForm.nilIfEmpty
            state.diplomaticForm = result.diplomaticForm.nilIfEmpty
            state.resolutionStatus = result.resolutionStatus
            state.supportLevel = result.supportLevel
            state.evidenceTier = result.evidenceTier
            state.derivationKind = result.derivationKind
            state.notes = result.notes
            state.provenance = result.provenance
            state.tokenBreakdown = result.tokenBreakdown
            state.unresolvedTokens = result.unresolvedTokens
            state.attestationRefs = result.attestationRefs
            state.inputLanguage = result.inputLanguage
            state.userFacingWarnings = result.userFacingWarnings
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
        quoteRepository: QuoteRepository
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
        quoteRepository: QuoteRepository,
        translationRepository: TranslationRepository
    ) throws -> (QuoteRecord, String) {
        let results = translationService.translateAllAvailable(
            text: input,
            fidelity: state.selectedFidelity,
            youngerVariant: state.selectedYoungerVariant,
            sourceLanguage: .english
        )
        guard results.contains(where: \.isAvailable) else {
            throw TranslationSaveError.noStructuredTranslationsAvailable
        }
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

private enum TranslationSaveError: LocalizedError {
    case noStructuredTranslationsAvailable

    var errorDescription: String? {
        switch self {
        case .noStructuredTranslationsAvailable:
            return "No structured historical translation is available for this input yet."
        }
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
