//
//  PhraseMatchInput.swift
//  RunicQuotes
//
//  Created by Claude on 09.10.26.
//

import Foundation

/// Phrase identity permits only modern terminal sentence punctuation to vary.
/// Internal punctuation, apostrophes, commas and lexical material retain their identity.
struct PhraseMatchInput: Sendable {
    let coreText: String
    let terminalSuffix: String

    init(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let reversedSuffix = trimmed.reversed().prefix { ".!?".contains($0) }
        self.terminalSuffix = String(reversedSuffix.reversed())
        self.coreText = String(trimmed.dropLast(self.terminalSuffix.count)).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var key: String {
        self.coreText.lowercased().replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
    }
}

extension TranslationResult {
    func preservingTerminalPunctuation(from source: String) -> TranslationResult {
        let suffix = PhraseMatchInput(source).terminalSuffix
        let warning = "Terminal punctuation is modern input punctuation; evidence applies to the phrase content."
        let punctuation = TranslationTokenBreakdown(sourceToken: suffix, normalizedToken: suffix, diplomaticToken: suffix, glyphToken: suffix, resolutionStatus: .reconstructed, provenance: [])
        return TranslationResult(
            sourceText: source, script: self.script, fidelity: self.fidelity,
            derivationKind: self.derivationKind, historicalStage: self.historicalStage,
            normalizedForm: PhraseMatchInput(self.normalizedForm).coreText + suffix,
            diplomaticForm: PhraseMatchInput(self.diplomaticForm).coreText + suffix,
            glyphOutput: PhraseMatchInput(self.glyphOutput).coreText + suffix,
            requestedVariant: self.requestedVariant, resolutionStatus: self.resolutionStatus,
            supportLevel: self.supportLevel, evidenceTier: self.evidenceTier, confidence: self.confidence,
            notes: self.notes, unresolvedTokens: self.unresolvedTokens, provenance: self.provenance,
            tokenBreakdown: self.tokenBreakdown + (suffix.isEmpty ? [] : [punctuation]),
            attestationRefs: self.attestationRefs, inputLanguage: self.inputLanguage,
            userFacingWarnings: self.userFacingWarnings + (suffix.isEmpty ? [] : [warning]),
            engineVersion: self.engineVersion, datasetVersion: self.datasetVersion,
            createdAt: self.createdAt, updatedAt: self.updatedAt,
        )
    }
}
