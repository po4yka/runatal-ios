//
//  RunicQuoteEntry.swift
//  RunicQuotesWidget
//
//  Created by Claude on 2025-11-15.
//

import WidgetKit
import SwiftUI

/// Timeline entry for the widget
struct RunicQuoteEntry: TimelineEntry {
    /// Date when this entry should be displayed
    let date: Date

    /// The quote to display
    let quote: QuoteData

    /// Selected runic script
    let script: RunicScript

    /// Selected font
    let font: RunicFont

    /// Selected visual theme
    let theme: AppTheme

    /// Widget display mode
    let widgetMode: WidgetMode

    /// Widget visual hierarchy style
    let widgetStyle: WidgetStyle

    /// Whether decorative identity elements are enabled
    let showsDecorativeGlyphs: Bool

    /// Create a placeholder entry for widget previews
    static func placeholder() -> RunicQuoteEntry {
        RunicQuoteEntry(
            date: Date(),
            quote: QuoteData.sample,
            script: .elder,
            font: .noto,
            theme: .obsidian,
            widgetMode: .daily,
            widgetStyle: .runeFirst,
            showsDecorativeGlyphs: true
        )
    }
}

/// Simplified quote data for widgets (non-SwiftData)
struct QuoteData: Codable, Sendable {
    let textLatin: String
    let author: String
    let runicElder: String?
    let runicYounger: String?
    let runicCirth: String?

    /// Get runic text for a specific script
    func runicText(for script: RunicScript) -> String {
        switch script {
        case .elder:
            return runicElder ?? textLatin
        case .younger:
            return runicYounger ?? textLatin
        case .cirth:
            return runicCirth ?? textLatin
        }
    }

    /// Create from a Quote model
    init(from quote: Quote) {
        self.textLatin = quote.textLatin
        self.author = quote.author
        self.runicElder = quote.runicElder
        self.runicYounger = quote.runicYounger
        self.runicCirth = quote.runicCirth
    }

    /// Create from a sendable quote snapshot
    init(from quote: QuoteRecord) {
        self.textLatin = quote.textLatin
        self.author = quote.author
        self.runicElder = quote.runicElder
        self.runicYounger = quote.runicYounger
        self.runicCirth = quote.runicCirth
    }

    /// Initialize with raw values
    init(textLatin: String, author: String, runicElder: String?, runicYounger: String?, runicCirth: String?) {
        self.textLatin = textLatin
        self.author = author
        self.runicElder = runicElder
        self.runicYounger = runicYounger
        self.runicCirth = runicCirth
    }

    /// Sample quote for previews
    static var sample: QuoteData {
        QuoteData(
            textLatin: "Not all those who wander are lost.",
            author: "J.R.R. Tolkien",
            runicElder: "ᚾᛟᛏ ᚨᛚᛚ ᚦᛟᛋᛖ ᚹᚺᛟ ᚹᚨᚾᛞᛖᚱ ᚨᚱᛖ ᛚᛟᛋᛏ",
            runicYounger: "ᚾᚨᛏ ᚨᛚᛚ ᚦᚨᛋᚨ ᚹᚺᚨ ᚹᚨᚾᛞᚨᚱ ᚨᚱᚨ ᛚᚨᛋᛏ",
            runicCirth: "⸸⸸⸸ ⸸⸸⸸ ⸸⸸⸸⸸ ⸸⸸⸸ ⸸⸸⸸⸸⸸⸸ ⸸⸸⸸ ⸸⸸⸸⸸"
        )
    }

    /// Sample quotes for testing
    static var samples: [QuoteData] {
        [
            sample,
            QuoteData(
                textLatin: "Fortune favors the bold.",
                author: "Virgil",
                runicElder: "ᚠᛟᚱᛏᚢᚾᛖ ᚠᚨᚡᛟᚱᛋ ᚦᛖ ᛒᛟᛚᛞ",
                runicYounger: "ᚠᚨᚱᛏᚢᚾᚨ ᚠᚨᚡᚨᚱᛋ ᚦᚨ ᛒᚨᛚᛞ",
                runicCirth: "⸸⸸⸸⸸⸸⸸⸸ ⸸⸸⸸⸸⸸⸸ ⸸⸸⸸ ⸸⸸⸸⸸"
            ),
            QuoteData(
                textLatin: "The only way out is through.",
                author: "Robert Frost",
                runicElder: "ᚦᛖ ᛟᚾᛚᚤ ᚹᚨᚤ ᛟᚢᛏ ᛁᛋ ᚦᚱᛟᚢᚷᚺ",
                runicYounger: "ᚦᚨ ᚨᚾᛚᛁ ᚹᚨᛁ ᚨᚢᛏ ᛁᛋ ᚦᚱᚨᚢᚷᚺ",
                runicCirth: "⸸⸸⸸ ⸸⸸⸸⸸ ⸸⸸⸸ ⸸⸸⸸ ⸸⸸ ⸸⸸⸸⸸⸸⸸⸸"
            )
        ]
    }
}
