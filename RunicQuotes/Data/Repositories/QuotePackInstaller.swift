//
//  QuotePackInstaller.swift
//  RunicQuotes
//
//  Created by Claude on 09.10.26.
//

import Foundation
import SwiftData

/// Imports content, durable quote identities and the installed flag in one owned transaction.
final class QuotePackInstaller: @unchecked Sendable {
    private let container: ModelContainer
    private let commit: @Sendable (ModelContext) throws -> Void

    init(modelContext: ModelContext, commit: @escaping @Sendable (ModelContext) throws -> Void = { try $0.save() }) {
        self.container = modelContext.container
        self.commit = commit
    }

    @discardableResult
    func install(packID: String) throws -> Int {
        guard let pack = try QuotePack.loadCatalog().first(where: { $0.id == packID }) else {
            throw QuoteRepositoryError.invalidSeedData
        }
        let context = ModelContext(self.container)
        context.autosaveEnabled = false
        do {
            let preferences = try UserPreferences.getOrCreate(in: context)
            let added = try Self.stage(pack: pack, in: context)
            preferences.installedPackIDs.insert(pack.id)
            try self.commit(context)
            NotificationCenter.default.post(name: .libraryDidChange, object: nil)
            NotificationCenter.default.post(name: .preferencesDidChange, object: nil)
            return added
        } catch {
            context.rollback()
            throw error
        }
    }

    /// Also repairs legacy installed flags that previously imported no content.
    static func stageLegacyInstalls(in context: ModelContext) throws {
        let preferences = try context.fetch(FetchDescriptor<UserPreferences>())
        let installed = preferences.reduce(into: Set<String>()) { $0.formUnion($1.installedPackIDs) }
        guard !installed.isEmpty else { return }
        for pack in try QuotePack.loadCatalog() where installed.contains(pack.id) {
            _ = try Self.stage(pack: pack, in: context)
        }
    }

    private static func stage(pack: QuotePack, in context: ModelContext) throws -> Int {
        let knownIDs = try Set(context.fetch(FetchDescriptor<QuoteSeedReceipt>()).map(\.seedID))
        var added = 0
        for entry in pack.quotes {
            let identity = "pack:\(pack.id):\(entry.id)"
            guard !knownIDs.contains(identity) else { continue }
            let quote = Quote(textLatin: entry.textLatin, author: entry.author, collection: entry.collection)
            quote.id = QuoteSeedReceipt.stableQuoteID(for: identity)
            quote.builtInID = identity
            quote.source = entry.source
            quote.runicElder = RunicTransliterator.transliterate(entry.textLatin, to: .elder).glyphOutput
            quote.runicYounger = RunicTransliterator.transliterate(entry.textLatin, to: .younger).glyphOutput
            quote.runicCirth = RunicTransliterator.transliterate(entry.textLatin, to: .cirth).glyphOutput
            context.insert(quote)
            context.insert(QuoteSeedReceipt(seedID: identity, quoteID: quote.id))
            added += 1
        }
        return added
    }
}
