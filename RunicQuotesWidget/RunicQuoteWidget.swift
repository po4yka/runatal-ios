//
//  RunicQuoteWidget.swift
//  RunicQuotesWidget
//
//  Created by Claude on 2025-11-15.
//

import WidgetKit
import SwiftUI

/// Main widget definition
struct RunicQuoteWidget: Widget {
    let kind: String = "RunicQuoteWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuoteTimelineProvider()) { entry in
            RunicQuoteWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    // Widget background
                    LinearGradient(
                        colors: entry.theme.palette.widgetBackgroundGradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
        }
        .configurationDisplayName("Runic Quote")
        .description("Display inspirational quotes in ancient runic scripts.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}

/// Widget bundle
@main
struct RunicQuotesWidgetBundle: WidgetBundle {
    var body: some Widget {
        RunicQuoteWidget()
    }
}
