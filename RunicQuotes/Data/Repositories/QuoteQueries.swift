//
//  QuoteQueries.swift
//  RunicQuotes
//
//  Created by Claude on 09.10.26.
//

import Foundation
import SwiftData

/// Shared visibility and ordering keep limited daily/random reads aligned with full library reads.
enum QuoteQueries {
    static func descriptor() -> FetchDescriptor<Quote> {
        FetchDescriptor<Quote>(
            predicate: #Predicate { !$0.isHidden && !$0.isSoftDeleted },
            sortBy: [SortDescriptor(\.createdAt)],
        )
    }

    static func visible(in context: ModelContext) throws -> [Quote] {
        try context.fetch(self.descriptor())
    }

    static func count(in context: ModelContext) throws -> Int {
        try context.fetchCount(self.descriptor())
    }

    static func quote(at index: Int, in context: ModelContext) throws -> Quote {
        var descriptor = self.descriptor()
        descriptor.fetchLimit = 1
        descriptor.fetchOffset = index
        guard let quote = try context.fetch(descriptor).first else { throw QuoteRepositoryError.noQuotesAvailable }
        return quote
    }
}
