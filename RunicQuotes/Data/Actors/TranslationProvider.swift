//
//  TranslationProvider.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import Foundation

/// Thread-safe wrapper around structured translation cache access.
actor TranslationProvider {
    private let repository: TranslationRepository

    init(repository: TranslationRepository) {
        self.repository = repository
    }

    func latestTranslation(for quoteID: UUID, script: RunicScript) throws -> TranslationResult? {
        try self.repository.latestTranslation(for: quoteID, script: script)
    }

    func cache(result: TranslationResult, for quoteID: UUID, sourceText: String) throws {
        try self.repository.cache(result: result, for: quoteID, sourceText: sourceText)
    }

    func cache(results: [TranslationResult], for quoteID: UUID, sourceText: String) throws {
        try self.repository.cache(results: results, for: quoteID, sourceText: sourceText)
    }

    func deleteTranslations(for quoteID: UUID) throws {
        try self.repository.deleteTranslations(for: quoteID)
    }

    func backfillAllQuotes() throws {
        try self.repository.backfillAllQuotes()
    }
}
