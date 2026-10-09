//
//  QuoteRecord.swift
//  RunicQuotes
//
//  Created by Claude on 09.10.26.
//

import Foundation

/// Sendable snapshot of a Quote model used across actor boundaries.
struct QuoteRecord: Identifiable {
    let id: UUID
    let textLatin: String
    let author: String
    let source: String?
    let collection: QuoteCollection
    let runicElder: String?
    let runicYounger: String?
    let runicCirth: String?
    let cirthEncodingRaw: String?
    let storedTranslationMetadataData: Data?
    let createdAt: Date
    let isHidden: Bool
    let isDeleted: Bool
    let deletedAt: Date?
    let isUserGenerated: Bool

    init(from quote: Quote) {
        self.id = quote.id
        self.textLatin = quote.textLatin
        self.author = quote.author
        self.source = quote.source
        self.collection = quote.collection
        self.runicElder = quote.runicElder
        self.runicYounger = quote.runicYounger
        self.runicCirth = quote.runicCirth
        self.cirthEncodingRaw = quote.cirthEncodingRaw
        self.storedTranslationMetadataData = quote.storedTranslationMetadataData
        self.createdAt = quote.createdAt
        self.isHidden = quote.isHidden
        self.isDeleted = quote.isSoftDeleted
        self.deletedAt = quote.deletedAt
        self.isUserGenerated = quote.isUserGenerated
    }

    func runicText(for script: RunicScript) -> String? {
        switch script {
        case .elder:
            self.runicElder
        case .younger:
            self.runicYounger
        case .cirth:
            self.runicCirth
        }
    }
}
