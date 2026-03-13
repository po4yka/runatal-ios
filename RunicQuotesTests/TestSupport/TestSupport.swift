//
//  TestSupport.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import Foundation
@testable import RunicQuotes
import SwiftData
import Testing

enum TestSupport {
    static func makeModelContainer() throws -> ModelContainer {
        let schema = Schema([Quote.self, UserPreferences.self, TranslationRecord.self, TranslationBackfillState.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: configuration)
    }

    static func makeModelContext() throws -> ModelContext {
        try ModelContext(self.makeModelContainer())
    }

    static func makeSeededRepository(in context: ModelContext) throws -> SwiftDataQuoteRepository {
        let repository = SwiftDataQuoteRepository(modelContext: context)
        try repository.seedIfNeeded()
        return repository
    }

    @MainActor
    static func eventually(
        timeout: Duration = .seconds(2),
        pollInterval: Duration = .milliseconds(25),
        condition: @escaping @MainActor () -> Bool,
    ) async -> Bool {
        let clock = ContinuousClock()
        let deadline = clock.now + timeout

        while clock.now < deadline {
            if condition() {
                return true
            }

            try? await Task.sleep(for: pollInterval)
        }

        return condition()
    }

    static func makeQuoteRecord(
        id: UUID = UUID(),
        text: String = "The wolf hunts at night",
        author: String = "Runatal",
        source: String? = nil,
        collection: QuoteCollection = .motivation,
        runicElder: String? = "ᚦᛖ ᚹᚢᛚᚠ",
        runicYounger: String? = "ᚦᚨ ᚢᛚᚠᚱ",
        runicCirth: String? = "wolf",
        createdAt: Date = Date(timeIntervalSince1970: 1_700_000_000),
        isHidden: Bool = false,
        isDeleted: Bool = false,
        deletedAt: Date? = nil,
        isUserGenerated: Bool = false,
    ) -> QuoteRecord {
        let quote = Quote(
            textLatin: text,
            author: author,
            collection: collection,
            isUserGenerated: isUserGenerated,
        )
        quote.id = id
        quote.source = source
        quote.runicElder = runicElder
        quote.runicYounger = runicYounger
        quote.runicCirth = runicCirth
        quote.createdAt = createdAt
        quote.isHidden = isHidden
        quote.isSoftDeleted = isDeleted
        quote.deletedAt = deletedAt
        return QuoteRecord(from: quote)
    }

    static func makeTranslationResult(
        sourceText: String = "The wolf hunts at night",
        script: RunicScript = .younger,
        fidelity: TranslationFidelity = .strict,
        derivationKind: TranslationDerivationKind = .goldExample,
        historicalStage: HistoricalStage? = nil,
        normalizedForm: String = "normalized",
        diplomaticForm: String = "diplomatic",
        glyphOutput: String = "ᛏᛖᛋᛏ",
        requestedVariant: String? = nil,
        resolutionStatus: TranslationResolutionStatus = .reconstructed,
        supportLevel: TranslationSupportLevel? = nil,
        evidenceTier: TranslationEvidenceTier? = nil,
        confidence: Double = 0.9,
        notes: [String] = [],
        unresolvedTokens: [String] = [],
        provenance: [TranslationProvenanceEntry] = [],
        tokenBreakdown: [TranslationTokenBreakdown] = [],
        attestationRefs: [String] = [],
        inputLanguage: TranslationSourceLanguage = .english,
        userFacingWarnings: [String] = [],
        engineVersion: String = "test-engine",
        datasetVersion: String = "test-dataset",
        createdAt: Date = Date(timeIntervalSince1970: 1_700_000_000),
        updatedAt: Date? = nil,
    ) -> TranslationResult {
        TranslationResult(
            sourceText: sourceText,
            script: script,
            fidelity: fidelity,
            derivationKind: derivationKind,
            historicalStage: historicalStage ?? (script == .cirth ? .ereborEnglish : .oldNorse),
            normalizedForm: normalizedForm,
            diplomaticForm: diplomaticForm,
            glyphOutput: glyphOutput,
            requestedVariant: requestedVariant,
            resolutionStatus: resolutionStatus,
            supportLevel: supportLevel,
            evidenceTier: evidenceTier,
            confidence: confidence,
            notes: notes,
            unresolvedTokens: unresolvedTokens,
            provenance: provenance,
            tokenBreakdown: tokenBreakdown,
            attestationRefs: attestationRefs,
            inputLanguage: inputLanguage,
            userFacingWarnings: userFacingWarnings,
            engineVersion: engineVersion,
            datasetVersion: datasetVersion,
            createdAt: createdAt,
            updatedAt: updatedAt,
        )
    }
}
