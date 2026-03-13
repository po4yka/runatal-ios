//
//  QuoteData.swift
//  RunicQuotes
//
//  Created by Claude on 09.10.25.
//

import Foundation

/// Simplified quote data shared by the app, package tests, and widget extension.
struct QuoteData: Codable, Equatable {
    let textLatin: String
    let author: String
    let runicElder: String?
    let runicYounger: String?
    let runicCirth: String?

    func runicText(for script: RunicScript) -> String {
        switch script {
        case .elder:
            self.runicElder ?? self.textLatin
        case .younger:
            self.runicYounger ?? self.textLatin
        case .cirth:
            self.runicCirth ?? self.textLatin
        }
    }

    init(from quote: Quote) {
        self.textLatin = quote.textLatin
        self.author = quote.author
        self.runicElder = quote.runicElder
        self.runicYounger = quote.runicYounger
        self.runicCirth = quote.runicCirth
    }

    init(from quote: QuoteRecord) {
        self.textLatin = quote.textLatin
        self.author = quote.author
        self.runicElder = quote.runicElder
        self.runicYounger = quote.runicYounger
        self.runicCirth = quote.runicCirth
    }

    init(
        textLatin: String,
        author: String,
        runicElder: String?,
        runicYounger: String?,
        runicCirth: String?,
    ) {
        self.textLatin = textLatin
        self.author = author
        self.runicElder = runicElder
        self.runicYounger = runicYounger
        self.runicCirth = runicCirth
    }

    static var sample: QuoteData {
        QuoteData(
            textLatin: "Not all those who wander are lost.",
            author: "J.R.R. Tolkien",
            runicElder: "ᚾᛟᛏ ᚨᛚᛚ ᚦᛟᛋᛖ ᚹᚺᛟ ᚹᚨᚾᛞᛖᚱ ᚨᚱᛖ ᛚᛟᛋᛏ",
            runicYounger: "ᚾᚨᛏ ᚨᛚᛚ ᚦᚨᛋᚨ ᚹᚺᚨ ᚹᚨᚾᛞᚨᚱ ᚨᚱᚨ ᛚᚨᛋᛏ",
            runicCirth: "⸸⸸⸸ ⸸⸸⸸ ⸸⸸⸸⸸ ⸸⸸⸸ ⸸⸸⸸⸸⸸⸸ ⸸⸸⸸ ⸸⸸⸸⸸",
        )
    }

    static var samples: [QuoteData] {
        [
            sample,
            QuoteData(
                textLatin: "Fortune favors the bold.",
                author: "Virgil",
                runicElder: "ᚠᛟᚱᛏᚢᚾᛖ ᚠᚨᚡᛟᚱᛋ ᚦᛖ ᛒᛟᛚᛞ",
                runicYounger: "ᚠᚨᚱᛏᚢᚾᚨ ᚠᚨᚡᚨᚱᛋ ᚦᚨ ᛒᚨᛚᛞ",
                runicCirth: "⸸⸸⸸⸸⸸⸸⸸ ⸸⸸⸸⸸⸸⸸ ⸸⸸⸸ ⸸⸸⸸⸸",
            ),
            QuoteData(
                textLatin: "The only way out is through.",
                author: "Robert Frost",
                runicElder: "ᚦᛖ ᛟᚾᛚᚤ ᚹᚨᚤ ᛟᚢᛏ ᛁᛋ ᚦᚱᛟᚢᚷᚺ",
                runicYounger: "ᚦᚨ ᚨᚾᛚᛁ ᚹᚨᛁ ᚨᚢᛏ ᛁᛋ ᚦᚱᚨᚢᚷᚺ",
                runicCirth: "⸸⸸⸸ ⸸⸸⸸⸸ ⸸⸸⸸ ⸸⸸⸸ ⸸⸸ ⸸⸸⸸⸸⸸⸸⸸",
            ),
        ]
    }
}
