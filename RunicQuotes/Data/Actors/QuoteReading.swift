//
//  QuoteReading.swift
//  RunicQuotes
//
//  Created by Claude on 09.10.26.
//

import Foundation

protocol QuoteReading: Sendable {
    func allQuotes() async throws -> [QuoteRecord]
    func hideQuote(id: UUID) async throws -> QuoteRecord
    func softDeleteQuote(id: UUID, deletedAt: Date) async throws -> QuoteRecord
}

protocol QuoteTranslationReading: Sendable {
    func latestTranslation(for quoteID: UUID, script: RunicScript) async throws -> TranslationResult?
}

extension QuoteProvider: QuoteReading {}
extension TranslationProvider: QuoteTranslationReading {}
