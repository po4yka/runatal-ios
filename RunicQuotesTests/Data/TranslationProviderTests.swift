//
//  TranslationProviderTests.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import Foundation
@testable import RunicQuotes
import SwiftData
import Testing

@Suite(.serialized, .tags(.actors))
struct TranslationProviderTests {
    @Test
    func forwardsRepositoryCalls() async throws {
        let repository = TestTranslationRepository()
        let quoteID = UUID()
        let result = TestSupport.makeTranslationResult(script: .elder)
        repository.latestTranslationResults = [quoteID: [.elder: result]]
        let provider = try TranslationProvider(modelContainer: TestSupport.makeModelContainer(), repositoryFactory: { _ in repository })

        #expect(try await provider.latestTranslation(for: quoteID, script: .elder)?.glyphOutput == result.glyphOutput)

        try await provider.cache(result: result, for: quoteID, sourceText: result.sourceText)
        try await provider.cache(results: [result], for: quoteID, sourceText: result.sourceText)
        try await provider.deleteTranslations(for: quoteID)
        try await provider.backfillAllQuotes()

        #expect(repository.cacheCalls.count == 2)
        #expect(repository.deleteCalls == [quoteID])
        #expect(repository.backfillCallCount == 1)
    }

    @Test
    func propagatesRepositoryErrors() async throws {
        let repository = TestTranslationRepository()
        repository.latestTranslationError = TestError(message: "translation failed")
        let provider = try TranslationProvider(modelContainer: TestSupport.makeModelContainer(), repositoryFactory: { _ in repository })

        var didThrow = false
        do {
            _ = try await provider.latestTranslation(for: UUID(), script: .elder)
        } catch {
            didThrow = true
            #expect((error as? TestError)?.message == "translation failed")
        }

        #expect(didThrow)
    }

    @MainActor
    @Test
    func mainContextCacheEditsAreVisibleThroughExistingProvider() async throws {
        let container = try TestSupport.makeModelContainer()
        let uiRepository = SwiftDataTranslationRepository(modelContext: container.mainContext)
        let quotes = SwiftDataQuoteRepository(modelContext: container.mainContext)
        let quote = try quotes.createQuote(textLatin: "The wolf hunts at night", author: "Audit", source: nil, collection: .stoic)
        let quoteID = quote.id
        let service = HistoricalTranslationService()
        let first = service.translate(text: quote.textLatin, script: .younger, fidelity: .strict, youngerVariant: .longBranch)
        try uiRepository.cache(result: first, for: quoteID, sourceText: quote.textLatin)
        let provider = TranslationProvider(modelContainer: container)
        #expect(try await provider.latestTranslation(for: quoteID, script: .younger)?.glyphOutput == first.glyphOutput)
        let revised = service.translate(text: quote.textLatin, script: .younger, fidelity: .strict, youngerVariant: .shortTwig)
        try uiRepository.cache(result: revised, for: quoteID, sourceText: quote.textLatin)
        #expect(try await provider.latestTranslation(for: quoteID, script: .younger)?.glyphOutput == revised.glyphOutput)
    }

    @MainActor
    @Test
    func actorCacheWritePersistsForAnotherContext() async throws {
        let container = try TestSupport.makeModelContainer()
        let provider = TranslationProvider(modelContainer: container)
        let quote = try SwiftDataQuoteRepository(modelContext: container.mainContext).createQuote(
            textLatin: "The wolf hunts at night", author: "Audit", source: nil, collection: .stoic,
        )
        let result = HistoricalTranslationService().translate(text: quote.textLatin, script: .younger, fidelity: .strict)
        try await provider.cache(result: result, for: quote.id, sourceText: quote.textLatin)
        let persistedRepository = SwiftDataTranslationRepository(modelContext: ModelContext(container))
        #expect(try persistedRepository.latestTranslation(for: quote.id, script: .younger)?.glyphOutput == result.glyphOutput)
    }
}
