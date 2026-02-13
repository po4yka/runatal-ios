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
}
