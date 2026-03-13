//
//  TranslationProviderTests.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import Foundation
@testable import RunicQuotes
import Testing

@Suite(.serialized, .tags(.actors))
struct TranslationProviderTests {
    @Test
    func forwardsRepositoryCalls() async throws {
        let repository = TestTranslationRepository()
        let quoteID = UUID()
        let result = TestSupport.makeTranslationResult(script: .elder)
        repository.latestTranslationResults = [quoteID: [.elder: result]]
        let provider = TranslationProvider(repository: repository)

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
    func propagatesRepositoryErrors() async {
        let repository = TestTranslationRepository()
        repository.latestTranslationError = TestError(message: "translation failed")
        let provider = TranslationProvider(repository: repository)

        var didThrow = false
        do {
            _ = try await provider.latestTranslation(for: UUID(), script: .elder)
        } catch {
            didThrow = true
            #expect((error as? TestError)?.message == "translation failed")
        }

        #expect(didThrow)
    }
}
