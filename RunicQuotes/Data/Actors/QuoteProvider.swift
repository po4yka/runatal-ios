//
//  QuoteProvider.swift
//  RunicQuotes
//
//  Created by Claude on 2025-11-15.
//

import Foundation

/// Thread-safe actor for providing quotes
/// Avoids race conditions when both app and widget access quotes
actor QuoteProvider {
    private let repository: QuoteRepository

    init(repository: QuoteRepository) {
        self.repository = repository
    }

    /// Get the quote of the day for a specific script
    func quoteOfTheDay(for script: RunicScript) async throws -> QuoteRecord {
        try repository.quoteOfTheDay(for: script)
    }

    /// Get a random quote for a specific script
    func randomQuote(for script: RunicScript) async throws -> QuoteRecord {
        try repository.randomQuote(for: script)
    }

    /// Seed the database if needed
    func seedIfNeeded() async throws {
        try repository.seedIfNeeded()
    }

    /// Get all quotes
    func allQuotes() async throws -> [QuoteRecord] {
        try repository.allQuotes()
    }

    /// Get a quote by id regardless of archive state.
    func quote(id: UUID) async throws -> QuoteRecord? {
        try repository.quote(id: id)
    }

    /// Get hidden and soft-deleted quotes.
    func archivedQuotes() async throws -> [QuoteRecord] {
        try repository.archivedQuotes()
    }

    /// Hide a quote without deleting it.
    func hideQuote(id: UUID) async throws -> QuoteRecord {
        try repository.hideQuote(id: id)
    }

    /// Soft delete a quote.
    func softDeleteQuote(id: UUID, deletedAt: Date = Date()) async throws -> QuoteRecord {
        try repository.softDeleteQuote(id: id, deletedAt: deletedAt)
    }

    /// Restore an archived quote.
    func restoreQuote(id: UUID) async throws -> QuoteRecord {
        try repository.restoreQuote(id: id)
    }

    /// Erase a quote permanently.
    func eraseQuote(id: UUID) async throws {
        try repository.eraseQuote(id: id)
    }

    /// Purge soft-deleted quotes older than a cutoff date.
    func purgeDeletedQuotes(before cutoffDate: Date) async throws -> Int {
        try repository.purgeDeletedQuotes(before: cutoffDate)
    }
}
