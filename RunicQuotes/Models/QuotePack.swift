//
//  QuotePack.swift
//  RunicQuotes
//
//  Created by Claude on 12.03.26.
//

import Foundation

/// A bundled, source-located collection whose counts and previews reflect its actual content.
struct QuotePack: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let title: String
    let subtitle: String
    let description: String
    let runicGlyph: String
    let quotes: [QuoteCatalogEntry]

    var quoteCount: Int {
        self.quotes.count
    }

    var previewQuotes: [String] {
        Array(self.quotes.prefix(4).map(\.textLatin))
    }

    static func loadCatalog() throws -> [QuotePack] {
        let packs: [QuotePack] = try QuoteSeedCatalog.loadResource("quote-packs")
        guard Set(packs.map(\.id)).count == packs.count,
              packs.allSatisfy({ !$0.id.isEmpty && !$0.quotes.isEmpty }),
              packs.allSatisfy({ pack in
                  Set(pack.quotes.map(\.id)).count == pack.quotes.count && pack.quotes.allSatisfy {
                      !$0.id.isEmpty && !$0.textLatin.isEmpty && !$0.author.isEmpty && $0.source?.isEmpty == false
                  }
              }) else { throw QuoteRepositoryError.invalidSeedData }
        return packs
    }

    static var sample: QuotePack {
        QuotePack(
            id: "preview", title: "Preview Pack", subtitle: "Preview", description: "Preview quotes.", runicGlyph: "ᚠ",
            quotes: [QuoteCatalogEntry(id: "preview-1", textLatin: "Preview quote", author: "Preview", collection: .stoic)],
        )
    }

    static func == (lhs: QuotePack, rhs: QuotePack) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
}
