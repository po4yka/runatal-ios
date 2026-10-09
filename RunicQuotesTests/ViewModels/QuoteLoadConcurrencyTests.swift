//
//  QuoteLoadConcurrencyTests.swift
//  RunicQuotes
//
//  Created by Claude on 09.10.26.
//

import Combine
import Foundation
@testable import RunicQuotes
import SwiftData
import Testing

@MainActor
@Suite(.serialized, .tags(.viewModel))
struct QuoteLoadConcurrencyTests {
    @Test
    func supersededRealActorResponseCannotOverwriteCurrentScriptOrQuote() async throws {
        let context = try TestSupport.makeModelContext()
        let repository = SwiftDataQuoteRepository(modelContext: context)
        let first = try repository.createQuote(textLatin: "First passage", author: "Reader", source: nil, collection: .stoic, storedRunic: nil, translations: [])
        let second = try repository.createQuote(textLatin: "Second passage", author: "Reader", source: nil, collection: .stoic, storedRunic: nil, translations: [])
        let delayed = DelayedQuoteReader(base: QuoteProvider(modelContainer: context.container))
        let preferences = SwiftDataUserPreferencesRepository(modelContext: context)
        let model = QuoteViewModel(quoteProvider: delayed, translationProvider: TranslationProvider(modelContainer: context.container), preferencesRepository: preferences)
        var presentations: [PresentedQuote] = []
        let observation = model.$state.sink { state in
            if !state.isLoading {
                presentations.append(PresentedQuote(id: state.currentQuoteID, latin: state.latinText, runic: state.runicText, script: state.currentScript))
            }
        }
        model.onAppear()
        #expect(await waitForAsyncCondition { await delayed.isSuspended })
        _ = try repository.hideQuote(id: first.id)
        model.onScriptChanged(.cirth)
        model.onNextQuoteTapped()
        model.onLibraryChanged()
        #expect(await TestSupport.eventually { !model.state.isLoading && model.state.currentQuoteID == second.id })
        let expectedRunes = RunicTransliterator.transliterate(second.textLatin, to: .cirth).glyphOutput
        #expect(model.state.currentScript == .cirth)
        #expect(model.state.currentReadingMode == .random)
        #expect(model.state.runicText == expectedRunes)
        await delayed.release()
        #expect(await TestSupport.eventually { !model.state.isLoading })
        #expect(model.state.currentQuoteID == second.id)
        #expect(model.currentQuoteRecord()?.id == second.id)
        #expect(presentations.allSatisfy { $0.id == second.id && $0.latin == second.textLatin && $0.runic == expectedRunes && $0.script == .cirth })
        withExtendedLifetime(observation) {}
    }

    @Test
    func delayedRealTranslationCannotMixStateOrUndoPendingNextAfterCacheEvent() async throws {
        let context = try TestSupport.makeModelContext()
        let repository = SwiftDataQuoteRepository(modelContext: context)
        let first = try repository.createQuote(textLatin: "The wolf hunts at night", author: "Reader", source: nil, collection: .stoic, storedRunic: nil, translations: [])
        let second = try repository.createQuote(textLatin: "A quiet passage", author: "Reader", source: nil, collection: .stoic, storedRunic: nil, translations: [])
        let translations = DelayedTranslationReader(base: TranslationProvider(modelContainer: context.container))
        let model = QuoteViewModel(
            quoteProvider: QuoteProvider(modelContainer: context.container),
            translationProvider: translations,
            preferencesRepository: SwiftDataUserPreferencesRepository(modelContext: context),
        )
        model.onQuoteSaved(first.id)
        #expect(await TestSupport.eventually { !model.state.isLoading && model.state.currentQuoteID == first.id })
        var frames: [PresentedQuote] = []
        let observation = model.$state.sink { state in
            if !state.isLoading {
                frames.append(PresentedQuote(id: state.currentQuoteID, latin: state.latinText, runic: state.runicText, script: state.currentScript))
            }
        }
        await translations.blockNextLookup()
        model.onScriptChanged(.younger)
        #expect(await waitForAsyncCondition { await translations.isSuspended })
        _ = try repository.hideQuote(id: first.id)
        model.onNextQuoteTapped()
        model.onLibraryChanged()
        model.onTranslationCacheUpdated(for: first.id)
        #expect(await TestSupport.eventually { !model.state.isLoading && model.state.currentQuoteID == second.id })
        #expect(model.state.currentReadingMode == .random)
        let expected = RunicTransliterator.transliterate(second.textLatin, to: .younger).glyphOutput
        #expect(model.state.runicText == expected)
        await translations.release()
        #expect(await TestSupport.eventually { !model.state.isLoading })
        #expect(model.state.currentQuoteID == second.id)
        #expect(frames.allSatisfy { frame in
            (frame.id == first.id && frame.latin == first.textLatin && frame.script == .elder)
                || (frame.id == second.id && frame.latin == second.textLatin && frame.runic == expected && frame.script == .younger)
        })
        withExtendedLifetime(observation) {}
    }

    @Test
    func movedCurrentPassageDoesNotRemainOutsideSelectedCollection() async throws {
        let context = try TestSupport.makeModelContext()
        let repository = SwiftDataQuoteRepository(modelContext: context)
        let first = try repository.createQuote(textLatin: "Stoic passage", author: "Reader", source: nil, collection: .stoic, storedRunic: nil, translations: [])
        let preferences = SwiftDataUserPreferencesRepository(modelContext: context)
        try preferences.apply([.collection(.stoic)])
        let model = QuoteViewModel(quoteProvider: QuoteProvider(modelContainer: context.container), translationProvider: TranslationProvider(modelContainer: context.container), preferencesRepository: preferences)
        model.onAppear()
        #expect(await TestSupport.eventually { !model.state.isLoading })
        #expect(model.state.currentQuoteID == first.id)
        _ = try repository.updateQuote(id: first.id, textLatin: first.textLatin, author: first.author, source: nil, collection: .motivation, storedRunic: nil)
        model.onLibraryChanged()
        #expect(await TestSupport.eventually { !model.state.isLoading })
        #expect(model.state.currentQuoteID == nil)
        #expect(model.state.currentCollection == .stoic)
        #expect(model.state.runicText.isEmpty)
        #expect(model.state.errorMessage != nil)
        #expect(model.searchResults(for: "Stoic").isEmpty)
        #expect(model.state.collectionCovers.first(where: { $0.collection == .stoic })?.quoteCount == 0)
        #expect(model.state.collectionCovers.first(where: { $0.collection == .motivation })?.quoteCount == 1)
    }

    @Test
    func widgetScriptContextDoesNotOverwriteGlobalReadingPreferences() async throws {
        let context = try TestSupport.makeModelContext()
        let repository = SwiftDataQuoteRepository(modelContext: context)
        let quote = try repository.createQuote(textLatin: "Read this passage", author: "Reader", source: nil, collection: .stoic, storedRunic: nil, translations: [])
        let preferences = SwiftDataUserPreferencesRepository(modelContext: context)
        let model = QuoteViewModel(quoteProvider: QuoteProvider(modelContainer: context.container), translationProvider: TranslationProvider(modelContainer: context.container), preferencesRepository: preferences)
        model.onOpenQuoteDeepLink(quoteID: quote.id, scriptRaw: RunicScript.cirth.rawValue, modeRaw: WidgetMode.random.rawValue, collectionRaw: nil)
        #expect(await TestSupport.eventually { !model.state.isLoading })
        #expect(model.state.currentQuoteID == quote.id)
        #expect(model.state.currentScript == .cirth)
        #expect(model.state.currentFont.isCompatible(with: .cirth))
        #expect(try preferences.snapshot().selectedScript == .elder)
        #expect(try preferences.snapshot().widgetMode == .daily)
    }
}

private actor DelayedQuoteReader: QuoteReading {
    let base: QuoteProvider
    private var shouldSuspend = true
    private var continuation: CheckedContinuation<Void, Never>?
    var isSuspended: Bool {
        self.continuation != nil
    }

    init(base: QuoteProvider) {
        self.base = base
    }

    func allQuotes() async throws -> [QuoteRecord] {
        let quotes = try await self.base.allQuotes()
        if self.shouldSuspend {
            self.shouldSuspend = false
            await withCheckedContinuation { self.continuation = $0 }
        }
        return quotes
    }

    func hideQuote(id: UUID) async throws -> QuoteRecord {
        try await self.base.hideQuote(id: id)
    }

    func softDeleteQuote(id: UUID, deletedAt: Date) async throws -> QuoteRecord {
        try await self.base.softDeleteQuote(id: id, deletedAt: deletedAt)
    }

    func release() {
        self.continuation?.resume(); self.continuation = nil
    }
}

private func waitForAsyncCondition(_ condition: @escaping @Sendable () async -> Bool) async -> Bool {
    let clock = ContinuousClock()
    let deadline = clock.now + .seconds(2)
    while clock.now < deadline {
        if await condition() {
            return true
        }
        try? await Task.sleep(for: .milliseconds(10))
    }
    return await condition()
}

private struct PresentedQuote {
    let id: UUID?
    let latin: String
    let runic: String
    let script: RunicScript
}

private actor DelayedTranslationReader: QuoteTranslationReading {
    let base: TranslationProvider
    private var shouldSuspend = false
    private var continuation: CheckedContinuation<Void, Never>?
    var isSuspended: Bool {
        self.continuation != nil
    }

    init(base: TranslationProvider) {
        self.base = base
    }

    func blockNextLookup() {
        self.shouldSuspend = true
    }

    func latestTranslation(for quoteID: UUID, script: RunicScript) async throws -> TranslationResult? {
        let result = try await self.base.latestTranslation(for: quoteID, script: script)
        if self.shouldSuspend {
            self.shouldSuspend = false
            await withCheckedContinuation { self.continuation = $0 }
        }
        return result
    }

    func release() {
        self.continuation?.resume(); self.continuation = nil
    }
}
