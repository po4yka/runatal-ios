//
//  QuoteRepositoryPerformanceTests.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

@testable import RunicQuotes
import SwiftData
import XCTest

final class QuoteRepositoryPerformanceTests: XCTestCase {
    func testQuoteOfTheDayPerformance() throws {
        let context = try TestSupport.makeModelContext()
        let repository = SwiftDataQuoteRepository(modelContext: context)
        try repository.seedIfNeeded()

        measure {
            _ = try? repository.quoteOfTheDay(for: .elder)
        }
    }

    func testRandomQuotePerformance() throws {
        let context = try TestSupport.makeModelContext()
        let repository = SwiftDataQuoteRepository(modelContext: context)
        try repository.seedIfNeeded()

        measure {
            _ = try? repository.randomQuote(for: .elder)
        }
    }
}
