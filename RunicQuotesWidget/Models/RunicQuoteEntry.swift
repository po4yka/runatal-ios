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
            snapshot: WidgetTimelineEntryData(
                date: Date(),
                quote: .sample,
                script: .elder,
                font: .noto,
                theme: .obsidian,
                widgetMode: .daily,
                widgetStyle: .runeFirst,
                showsDecorativeGlyphs: true
            )
        )
    }

    init(snapshot: WidgetTimelineEntryData) {
        self.date = snapshot.date
        self.quote = snapshot.quote
        self.script = snapshot.script
        self.font = snapshot.font
        self.theme = snapshot.theme
        self.widgetMode = snapshot.widgetMode
        self.widgetStyle = snapshot.widgetStyle
        self.showsDecorativeGlyphs = snapshot.showsDecorativeGlyphs
    }
}
