//
//  ReadingAppearanceProgressTests.swift
//  RunicQuotes
//
//  Created by Claude on 09.10.26.
//

import Foundation
@testable import RunicQuotes
import Testing

@MainActor
@Suite(.serialized, .tags(.viewModel))
struct ReadingAppearanceProgressTests {
    @Test
    func continuousBackgroundEventsAllowTheSuspendedFirstLoadToComplete() async throws {
        let context = try TestSupport.makeModelContext()
        let quotes = SwiftDataQuoteRepository(modelContext: context)
        let preferences = SwiftDataUserPreferencesRepository(modelContext: context)
        let quote = try quotes.createQuote(textLatin: "Harja", author: "Reader", source: nil, collection: .stoic)
        let result = HistoricalTranslationService().translate(text: quote.textLatin, script: .elder)
        try SwiftDataTranslationRepository(modelContext: context).cache(result: result, for: quote.id, sourceText: quote.textLatin)
        let reader = SuspendedReadingLibrary(base: QuoteProvider(modelContainer: context.container))
        let model = ReadingAppearanceController(repository: preferences, quotes: reader, translations: TranslationProvider(modelContainer: context.container))
        #expect(await self.waitForSuspension(reader))
        let progress = AppearanceWriteProgress()
        let writes = Task.detached {
            for index in 0 ..< 60 {
                try preferences.apply([.decorativeGlyphs(index.isMultiple(of: 2))])
                try await Task.sleep(for: .milliseconds(20))
            }
            await progress.finish()
        }
        await reader.release()
        #expect(await TestSupport.eventually { model.presentation(for: quote).source == .structuredTranslation })
        let didFinish = await progress.isFinished
        #expect(!didFinish, "The first load must make progress while writes continue")
        #expect(model.presentation(for: quote).text == "ᚺᚨᚱᛃᚨ")
        try await writes.value
    }

    @Test
    func anOldPreferenceSnapshotCannotCommitAfterScriptChangesDuringTheLookup() async throws {
        let context = try TestSupport.makeModelContext()
        let quotes = SwiftDataQuoteRepository(modelContext: context)
        let preferences = SwiftDataUserPreferencesRepository(modelContext: context)
        let quote = try quotes.createQuote(textLatin: "Harja", author: "Reader", source: nil, collection: .stoic)
        let reader = SuspendedReadingLibrary(base: QuoteProvider(modelContainer: context.container))
        let model = ReadingAppearanceController(repository: preferences, quotes: reader, translations: TranslationProvider(modelContainer: context.container))
        #expect(await self.waitForSuspension(reader))
        try preferences.apply([.script(.younger)])
        await reader.release()
        #expect(await TestSupport.eventually { model.script == .younger })
        #expect(model.font.isCompatible(with: .younger))
        #expect(model.presentation(for: quote).text == RunicTransliterator.transliterate(quote.textLatin, to: .younger).glyphOutput)
    }

    private func waitForSuspension(_ reader: SuspendedReadingLibrary) async -> Bool {
        let clock = ContinuousClock()
        let deadline = clock.now + .seconds(2)
        while clock.now < deadline {
            if await reader.isSuspended {
                return true
            }
            try? await Task.sleep(for: .milliseconds(10))
        }
        return await reader.isSuspended
    }
}

private actor SuspendedReadingLibrary: ReadingLibraryProviding {
    private let base: QuoteProvider
    private var firstLookup = true
    private var continuation: CheckedContinuation<Void, Never>?
    var isSuspended: Bool {
        self.continuation != nil
    }

    init(base: QuoteProvider) {
        self.base = base
    }

    func readingLibraryQuotes() async throws -> [QuoteRecord] {
        let records = try await self.base.readingLibraryQuotes()
        if self.firstLookup {
            self.firstLookup = false
            await withCheckedContinuation { self.continuation = $0 }
        }
        return records
    }

    func release() {
        self.continuation?.resume()
        self.continuation = nil
    }
}

private actor AppearanceWriteProgress {
    private(set) var isFinished = false
    func finish() {
        self.isFinished = true
    }
}
