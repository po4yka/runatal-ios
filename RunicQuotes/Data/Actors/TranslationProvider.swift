//
//  TranslationProvider.swift
//  RunicQuotes
//
//  Created by Codex on 2026-03-13.
//

import Foundation

/// Thread-safe wrapper around structured translation cache access.
actor TranslationProvider {
    private let repository: TranslationRepository

    init(repository: TranslationRepository) {
        self.repository = repository
    }

    func latestTranslation(for quoteID: UUID, script: RunicScript) throws -> TranslationResult? {
        try repository.latestTranslation(for: quoteID, script: script)
    }

    func cache(result: TranslationResult, for quoteID: UUID, sourceText: String) throws {
        try repository.cache(result: result, for: quoteID, sourceText: sourceText)
    }

    func cache(results: [TranslationResult], for quoteID: UUID, sourceText: String) throws {
        try repository.cache(results: results, for: quoteID, sourceText: sourceText)
    }

    func deleteTranslations(for quoteID: UUID) throws {
        try repository.deleteTranslations(for: quoteID)
    }

    func backfillAllQuotes() throws {
        try repository.backfillAllQuotes()
    }
}
