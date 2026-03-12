//
//  RunicQuoteWidget.swift
//  RunicQuotesWidget
//
//  Created by Claude on 2025-11-15.
//

import WidgetKit
import SwiftUI

/// Main widget definition with AppIntent configuration
struct RunicQuoteWidget: Widget {
    let kind: String = "RunicQuoteWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: RunicQuoteConfigurationIntent.self,
            provider: QuoteTimelineProvider()
        ) { entry in
            RunicQuoteWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    WidgetBackgroundView(entry: entry)
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

/// Adaptive widget background using colorScheme
private struct WidgetBackgroundView: View {
    let entry: RunicQuoteEntry
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let palette = AppThemePalette.adaptive(for: colorScheme)
        LinearGradient(
            colors: palette.widgetBackgroundGradient,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

/// Widget bundle
@main
struct RunicQuotesWidgetBundle: WidgetBundle {
    var body: some Widget {
        RunicQuoteWidget()
    }
}
