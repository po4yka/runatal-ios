//
//  AttestedQuoteCatalogTests.swift
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
struct AttestedQuoteCatalogTests {
    @Test
    func shippedInscriptionEntriesHavePositiveStrictHistoricalCoverage() throws {
        let entries = try QuoteSeedCatalog.load().filter { $0.id.hasPrefix("builtin-inscription-") }
        #expect(entries.count == 4)
        let service = HistoricalTranslationService()
        for entry in entries {
            let script: RunicScript = entry.id.contains("-elder-") ? .elder : .younger
            let result = service.translate(text: entry.textLatin, script: script, fidelity: .strict)
            #expect(result.isAvailable)
            #expect(!result.glyphOutput.isEmpty)
            #expect(!result.attestationRefs.isEmpty)
            #expect(result.provenance.contains { $0.url?.contains("runesdb.de/en/find/") == true })
            if entry.id.hasSuffix("dr41") {
                #expect(result.evidenceTier == .reconstructed)
                #expect(entry.source?.contains("restored damaged") == true)
            } else {
                #expect(result.evidenceTier == .attested)
            }
        }
    }

    @Test
    func realSeedAndBackfillPublishInscriptionResultsAndKeepErasureReceipts() async throws {
        let context = try TestSupport.makeModelContext()
        let repository = SwiftDataQuoteRepository(modelContext: context)
        try repository.seedIfNeeded()
        let translations = SwiftDataTranslationRepository(modelContext: context)
        try await translations.backfillAllQuotes()
        let records = try repository.allQuotes()
        let name = try #require(records.first { $0.textLatin == "Harja" })
        let cached = try #require(try translations.latestTranslation(for: name.id, script: .elder))
        #expect(cached.evidenceTier == .attested)
        #expect(cached.glyphOutput == "ᚺᚨᚱᛃᚨ")
        try repository.eraseQuote(id: name.id)
        try repository.seedIfNeeded()
        #expect(try repository.quote(id: name.id) == nil)
        #expect(try repository.allQuotes().count == 43)
        #expect(try ModelContext(context.container).fetchCount(FetchDescriptor<QuoteSeedReceipt>()) == 44)
    }
}
