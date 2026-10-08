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
        let quoteID = UUID()
        let first = TestSupport.makeTranslationResult(script: .elder, glyphOutput: "ᚠ")
        try uiRepository.cache(result: first, for: quoteID, sourceText: first.sourceText)
        let provider = TranslationProvider(modelContainer: container)
        #expect(try await provider.latestTranslation(for: quoteID, script: .elder)?.glyphOutput == "ᚠ")

        let revised = TestSupport.makeTranslationResult(script: .elder, glyphOutput: "ᚢ")
        try uiRepository.cache(result: revised, for: quoteID, sourceText: revised.sourceText)

        #expect(try await provider.latestTranslation(for: quoteID, script: .elder)?.glyphOutput == "ᚢ")
    }

    @MainActor
    @Test
    func actorCacheWritePersistsForAnotherContext() async throws {
        let container = try TestSupport.makeModelContainer()
        let provider = TranslationProvider(modelContainer: container)
        let quoteID = UUID()
        let result = TestSupport.makeTranslationResult(script: .elder)

        try await provider.cache(result: result, for: quoteID, sourceText: result.sourceText)

        let persistedRepository = SwiftDataTranslationRepository(modelContext: ModelContext(container))
        #expect(try persistedRepository.latestTranslation(for: quoteID, script: .elder)?.glyphOutput == result.glyphOutput)
    }
}
