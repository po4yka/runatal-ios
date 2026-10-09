//
//  QuoteSeedCatalog.swift
//  RunicQuotes
//
//  Created by Claude on 09.10.26.
//

import Foundation

struct QuoteCatalogEntry: Codable, Sendable {
    let id: String
    let textLatin: String
    let author: String
    let collection: QuoteCollection
    var source: String?
}

enum QuoteSeedCatalog {
    static func load() throws -> [QuoteCatalogEntry] {
        try self.validatedEntries("quotes") + self.validatedEntries("attested-quotes")
    }

    static func legacyIdentities() throws -> [QuoteCatalogEntry] {
        try self.validatedEntries("legacy-quotes")
    }

    private static func validatedEntries(_ name: String) throws -> [QuoteCatalogEntry] {
        let entries: [QuoteCatalogEntry] = try self.loadResource(name)
        guard Set(entries.map(\.id)).count == entries.count, entries.allSatisfy({ !$0.id.isEmpty }) else {
            throw QuoteRepositoryError.invalidSeedData
        }
        return entries
    }

    static func identity(textLatin: String, author: String) -> String {
        "\(self.normalizeSeedField(textLatin))||\(self.normalizeSeedField(author))"
    }

    private static func normalizeSeedField(_ value: String) -> String {
        value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func loadResource<T: Decodable>(_ name: String) throws -> T {
        guard let url = self.resourceURL(name) else { throw QuoteRepositoryError.seedDataNotFound }
        let entries: T
        do {
            entries = try JSONDecoder().decode(T.self, from: Data(contentsOf: url))
        } catch {
            throw QuoteRepositoryError.invalidSeedData
        }
        return entries
    }

    private static func resourceURL(_ name: String) -> URL? {
        #if SWIFT_PACKAGE
            for subdirectory in [nil, "SeedData"] as [String?] {
                if let url = Bundle.module.url(forResource: name, withExtension: "json", subdirectory: subdirectory) {
                    return url
                }
            }
        #endif
        for subdirectory in [nil, "SeedData", "Resources/SeedData"] as [String?] {
            if let url = Bundle.main.url(forResource: name, withExtension: "json", subdirectory: subdirectory) {
                return url
            }
        }
        return nil
    }
}
