//
//  TranslationViewModel.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import Foundation
import os
import SwiftData
import SwiftUI

private let translationMaxInputLength = 280

struct TranslationUiState {
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
        max(0, translationMaxInputLength - self.inputText.count)
    }

    var isInputEmpty: Bool {
        self.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var fallbackSuggestion: String? {
        guard self.translationMode == .translate else { return nil }
        guard self.resolutionStatus == .unavailable else { return nil }
        if self.selectedFidelity == .strict {
            return "Try Readable or Decorative to allow approximated output."
        }
        return "This phrase has gaps in the curated dataset for the selected script."
    }

    var sourceLanguageBanner: String? {
        guard self.translationMode == .translate else { return nil }
        return "Historical translation currently supports English input only."
    }

    var primarySourceLabel: String? {
        self.provenance.first?.label
    }

    var primarySourceDetail: String? {
        self.provenance.first?.detail ?? self.provenance.first?.sourceWork
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
        translationService: HistoricalTranslationService = HistoricalTranslationService(),
    ) {
        self.quoteRepository = quoteRepository
        self.translationRepository = translationRepository
        self.preferencesRepository = preferencesRepository
        self.translationService = translationService
    }

    convenience init(
        modelContext: ModelContext,
        translationService: HistoricalTranslationService = HistoricalTranslationService(),
    ) {
        let translationRepository = SwiftDataTranslationRepository(
            modelContext: modelContext,
            translationService: translationService,
        )
        self.init(
            quoteRepository: SwiftDataQuoteRepository(
                modelContext: modelContext,
                translationCacheRepository: translationRepository,
            ),
            translationRepository: translationRepository,
            preferencesRepository: SwiftDataUserPreferencesRepository(modelContext: modelContext),
            translationService: translationService,
        )
    }

    func onAppear() {
        self.loadPreferences()
        self.rebuildPresentation()
    }

    func updateInputText(_ text: String) {
        self.state.inputText = String(text.prefix(translationMaxInputLength))
        self.state.errorMessage = nil
        self.state.successMessage = nil
        self.rebuildPresentation()
    }

    func selectMode(_ mode: TranslationMode) {
        self.state.translationMode = mode
        self.state.errorMessage = nil
        self.state.successMessage = nil
        self.rebuildPresentation()
    }

    func selectScript(_ script: RunicScript) {
        self.state.selectedScript = script
        if !self.state.selectedFont.isCompatible(with: script) {
            self.state.selectedFont = RunicFontConfiguration.recommendedFont(for: script)
        }
        self.preferences.selectedScript = script
        self.preferences.selectedFont = self.state.selectedFont
        self.persistPreferences()
        self.rebuildPresentation()
    }

    func selectFidelity(_ fidelity: TranslationFidelity) {
        self.state.selectedFidelity = fidelity
        self.rebuildPresentation()
    }

    func selectYoungerVariant(_ variant: YoungerFutharkVariant) {
        self.state.selectedYoungerVariant = variant
        self.rebuildPresentation()
    }

    func clearInput() {
        self.state.inputText = ""
        self.state.outputText = ""
        self.state.normalizedForm = nil
        self.state.diplomaticForm = nil
        self.state.notes = []
        self.state.provenance = []
        self.state.tokenBreakdown = []
        self.state.unresolvedTokens = []
        self.state.attestationRefs = []
        self.state.inputLanguage = .english
        self.state.userFacingWarnings = []
        self.state.resolutionStatus = nil
        self.state.supportLevel = nil
        self.state.evidenceTier = nil
        self.state.derivationKind = nil
        self.state.errorMessage = nil
        self.state.successMessage = nil
        self.state.didSave = false
    }

    func toggleWordByWordMode() {
        self.state.isWordByWordEnabled.toggle()
    }

    func setWordByWordEnabled(_ enabled: Bool) {
        self.state.isWordByWordEnabled = enabled
    }

    func saveToLibrary() {
        let input = self.state.inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else {
            self.state.errorMessage = "Enter a phrase to save."
            return
        }

        self.state.isSaving = true
        self.state.errorMessage = nil
        self.state.successMessage = nil
        self.state.didSave = false

        do {
            let savedQuote: QuoteRecord
            let saveMessage: String
            switch self.state.translationMode {
            case .transliterate:
                (savedQuote, saveMessage) = try self.saveTransliterationQuote(
                    input: input,
                    quoteRepository: self.quoteRepository,
                )

            case .translate:
                (savedQuote, saveMessage) = try self.saveStructuredQuote(
                    input: input,
                    quoteRepository: self.quoteRepository,
                    translationRepository: self.translationRepository,
                )
            }

            self.logger.info("Saved translation flow quote: \(savedQuote.id)")
            self.state.isSaving = false
            self.state.successMessage = saveMessage
            self.state.didSave = true
        } catch {
            self.state.isSaving = false
            self.state.errorMessage = error.localizedDescription
            self.logger.error("Failed to save translation flow quote: \(error.localizedDescription)")
        }
    }

    static func preview() -> TranslationViewModel {
        let container = ModelContainerHelper.createPlaceholderContainer()
        let context = ModelContext(container)
        let translationRepository = SwiftDataTranslationRepository(modelContext: context)
        return TranslationViewModel(
            quoteRepository: SwiftDataQuoteRepository(
                modelContext: context,
                translationCacheRepository: translationRepository,
            ),
            translationRepository: translationRepository,
            preferencesRepository: SwiftDataUserPreferencesRepository(modelContext: context),
        )
    }

    private func loadPreferences() {
        do {
            self.preferences = try self.preferencesRepository.snapshot()
            self.state.selectedScript = self.preferences.selectedScript
            self.state.selectedFont = self.preferences.selectedFont.isCompatible(with: self.preferences.selectedScript)
                ? self.preferences.selectedFont
                : RunicFontConfiguration.recommendedFont(for: self.preferences.selectedScript)
        } catch {
            self.state.errorMessage = "Failed to load preferences: \(error.localizedDescription)"
        }
    }

    private func persistPreferences() {
        do {
            try self.preferencesRepository.save(self.preferences)
        } catch {
            self.state.errorMessage = "Failed to save preferences: \(error.localizedDescription)"
        }
    }

    private func rebuildPresentation() {
        let input = self.state.inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else {
            self.state.outputText = ""
            self.state.normalizedForm = nil
            self.state.diplomaticForm = nil
            self.state.resolutionStatus = nil
            self.state.supportLevel = nil
            self.state.evidenceTier = nil
            self.state.derivationKind = nil
            self.state.notes = []
            self.state.provenance = []
            self.state.tokenBreakdown = []
            self.state.unresolvedTokens = []
            self.state.attestationRefs = []
            self.state.inputLanguage = .english
            self.state.userFacingWarnings = []
            return
        }

        switch self.state.translationMode {
        case .transliterate:
            self.state.outputText = RunicTransliterator.transliterate(input, to: self.state.selectedScript)
            self.state.normalizedForm = nil
            self.state.diplomaticForm = nil
            self.state.resolutionStatus = nil
            self.state.supportLevel = nil
            self.state.evidenceTier = nil
            self.state.derivationKind = nil
            self.state.notes = []
            self.state.provenance = []
            self.state.unresolvedTokens = []
            self.state.attestationRefs = []
            self.state.inputLanguage = .english
            self.state.userFacingWarnings = []
            self.state.tokenBreakdown = self.buildTransliterationBreakdown(for: input, script: self.state.selectedScript)

        case .translate:
            let result = self.translationService.translate(
                text: input,
                script: self.state.selectedScript,
                fidelity: self.state.selectedFidelity,
                youngerVariant: self.state.selectedYoungerVariant,
                sourceLanguage: .english,
            )
            self.state.outputText = result.glyphOutput
            self.state.normalizedForm = result.normalizedForm.nilIfEmpty
            self.state.diplomaticForm = result.diplomaticForm.nilIfEmpty
            self.state.resolutionStatus = result.resolutionStatus
            self.state.supportLevel = result.supportLevel
            self.state.evidenceTier = result.evidenceTier
            self.state.derivationKind = result.derivationKind
            self.state.notes = result.notes
            self.state.provenance = result.provenance
            self.state.tokenBreakdown = result.tokenBreakdown
            self.state.unresolvedTokens = result.unresolvedTokens
            self.state.attestationRefs = result.attestationRefs
            self.state.inputLanguage = result.inputLanguage
            self.state.userFacingWarnings = result.userFacingWarnings
        }
    }

    private func buildTransliterationBreakdown(
        for text: String,
        script: RunicScript,
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
                    provenance: [],
                )
            }
    }

    private func saveTransliterationQuote(
        input: String,
        quoteRepository: QuoteRepository,
    ) throws -> (QuoteRecord, String) {
        let bundle = RunicTextBundle(
            elder: RunicTransliterator.transliterate(input, to: .elder),
            younger: RunicTransliterator.transliterate(input, to: .younger),
            cirth: RunicTransliterator.transliterate(input, to: .cirth),
        )
        let savedQuote = try quoteRepository.createQuote(
            textLatin: input,
            author: "Runatal",
            source: nil,
            collection: .motivation,
            storedRunic: bundle,
        )
        return (savedQuote, String(localized: "translation.save.success"))
    }

    private func saveStructuredQuote(
        input: String,
        quoteRepository: QuoteRepository,
        translationRepository: TranslationRepository,
    ) throws -> (QuoteRecord, String) {
        let results = self.translationService.translateAllAvailable(
            text: input,
            fidelity: self.state.selectedFidelity,
            youngerVariant: self.state.selectedYoungerVariant,
            sourceLanguage: .english,
        )
        guard results.contains(where: \.isAvailable) else {
            throw TranslationSaveError.noStructuredTranslationsAvailable
        }
        let bundle = RunicTextBundle(
            elder: results.first(where: { $0.script == .elder && $0.isAvailable })?.glyphOutput,
            younger: results.first(where: { $0.script == .younger && $0.isAvailable })?.glyphOutput,
            cirth: results.first(where: { $0.script == .cirth && $0.isAvailable })?.glyphOutput,
        )
        let savedQuote = try quoteRepository.createQuote(
            textLatin: input,
            author: "Runatal",
            source: nil,
            collection: .motivation,
            storedRunic: bundle,
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
            "No structured historical translation is available for this input yet."
        }
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
