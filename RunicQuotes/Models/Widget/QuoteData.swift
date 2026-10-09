//
//  QuoteData.swift
//  RunicQuotes
//
//  Created by Claude on 09.10.25.
//

import Foundation

/// Simplified quote data shared by the app, package tests, and widget extension.
struct QuoteData: Codable, Equatable {
    let id: UUID
    let textLatin: String
    let author: String
    let runicElder: String?
    let runicYounger: String?
    let runicCirth: String?
    let cirthEncodingRaw: String?
    var presentation: ResolvedRunicPresentation?
    var presentationScript: RunicScript?
    var savedMetadata: Data?

    func runicRendering(for script: RunicScript) -> ResolvedRunicPresentation {
        if self.presentationScript == script, let presentation = self.presentation {
            return presentation
        }
        let stored: String? = switch script {
        case .elder: self.runicElder
        case .younger: self.runicYounger
        case .cirth: self.runicCirth
        }
        return RunicPresentationResolver.resolve(RunicPresentationInput(textLatin: self.textLatin, storedText: stored, script: script, cirthEncoding: self.cirthEncodingRaw, savedMetadata: self.savedMetadata), currentCache: nil)
    }

    init(from quote: Quote) {
        self.id = quote.id
        self.textLatin = quote.textLatin
        self.author = quote.author
        self.runicElder = quote.runicElder
        self.runicYounger = quote.runicYounger
        self.runicCirth = quote.runicCirth
        self.cirthEncodingRaw = quote.cirthEncodingRaw
    }

    init(from quote: QuoteRecord, presentation: ResolvedRunicPresentation? = nil, script: RunicScript? = nil) {
        self.presentation = presentation
        self.presentationScript = script
        self.savedMetadata = presentation == nil ? quote.storedTranslationMetadataData : nil
        self.id = quote.id
        self.textLatin = quote.textLatin
        self.author = quote.author
        self.runicElder = quote.runicElder
        self.runicYounger = quote.runicYounger
        self.runicCirth = quote.runicCirth
        self.cirthEncodingRaw = quote.cirthEncodingRaw
    }

    init(
        id: UUID,
        textLatin: String,
        author: String,
        runicElder: String?,
        runicYounger: String?,
        runicCirth: String?,
        cirthEncodingRaw: String? = nil,
    ) {
        self.id = id
        self.textLatin = textLatin
        self.author = author
        self.runicElder = runicElder
        self.runicYounger = runicYounger
        self.runicCirth = runicCirth
        self.cirthEncodingRaw = cirthEncodingRaw
    }

    static var sample: QuoteData {
        self.makeSample(id: 1, text: "Not all those who wander are lost.", author: "J.R.R. Tolkien")
    }

    static var samples: [QuoteData] {
        [
            self.sample,
            self.makeSample(id: 2, text: "Fortune favors the bold.", author: "Virgil"),
            self.makeSample(id: 3, text: "The only way out is through.", author: "Robert Frost"),
        ]
    }

    private static func makeSample(id: UInt8, text: String, author: String) -> QuoteData {
        QuoteData(
            id: UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, id)),
            textLatin: text,
            author: author,
            runicElder: RunicTransliterator.transliterate(text, to: .elder).glyphOutput,
            runicYounger: RunicTransliterator.transliterate(text, to: .younger).glyphOutput,
            runicCirth: RunicTransliterator.transliterate(text, to: .cirth).glyphOutput,
        )
    }
}
