//
//  TranslationBackfillTests.swift
//  RunicQuotes
//
//  Created by Claude on 09.10.26.
//

import Foundation
@testable import RunicQuotes
import SwiftData
import Testing

@MainActor
@Suite(.serialized, .tags(.repository))
struct TranslationBackfillTests {
    @Test
    func completedBackfillIncludesNewEditedAndRestoredQuotesAtSameVersion() async throws {
        let context = try TestSupport.makeModelContext()
        let quotes = SwiftDataQuoteRepository(modelContext: context)
        let translations = SwiftDataTranslationRepository(modelContext: context)
        let text = "The wolf hunts at night"
        let first = try quotes.createQuote(textLatin: text, author: "Audit", source: nil, collection: .stoic)
        try await translations.backfillAllQuotes()
        #expect(try translations.latestTranslation(for: first.id, script: .younger) != nil)
        let added = try quotes.createQuote(textLatin: text, author: "Audit", source: nil, collection: .stoic)
        let restored = try quotes.createQuote(textLatin: text, author: "Audit", source: nil, collection: .stoic)
        _ = try quotes.softDeleteQuote(id: restored.id)
        _ = try quotes.updateQuote(id: first.id, textLatin: "Changed source", author: "Audit", source: nil, collection: .stoic)
        try await translations.backfillAllQuotes()
        #expect(try translations.latestTranslation(for: added.id, script: .younger) != nil)
        #expect(try translations.latestTranslation(for: restored.id, script: .younger) == nil)
        _ = try quotes.restoreQuote(id: restored.id)
        try await translations.backfillAllQuotes()
        #expect(try translations.latestTranslation(for: restored.id, script: .younger) != nil)
        let persisted = ModelContext(context.container)
        let firstModel = try #require(persisted.fetch(FetchDescriptor<Quote>()).first { $0.id == first.id })
        #expect(firstModel.translationBackfillSourceText == "Changed source")
        let state = try #require(persisted.fetch(FetchDescriptor<TranslationBackfillState>()).first)
        #expect(state.isCompleted)
        #expect(state.processedCount == 3)
        let completedAt = state.completedAt
        try await translations.backfillAllQuotes()
        #expect(try ModelContext(context.container).fetch(FetchDescriptor<TranslationBackfillState>()).first?.completedAt == completedAt)
    }
}
