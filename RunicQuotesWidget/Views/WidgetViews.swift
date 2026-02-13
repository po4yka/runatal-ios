//
//  WidgetViewsWithDeepLink.swift
//  RunicQuotesWidget
//
//  Created by Claude on 2025-11-15.
//

import SwiftUI
import WidgetKit

// MARK: - Widget Entry View

/// Main view for the widget with deep link support
struct RunicQuoteWidgetEntryView: View {
    let entry: RunicQuoteEntry
    @Environment(\.widgetFamily) var widgetFamily

    var body: some View {
        Group {
            switch widgetFamily {
            case .systemSmall:
                SmallWidgetView(entry: entry)
            case .systemMedium:
                MediumWidgetView(entry: entry)
            case .systemLarge:
                LargeWidgetView(entry: entry)
            case .accessoryCircular:
                CircularWidgetView(entry: entry)
            case .accessoryRectangular:
                RectangularWidgetView(entry: entry)
            case .accessoryInline:
                InlineWidgetView(entry: entry)
            default:
                SmallWidgetView(entry: entry)
            }
        }
        .widgetURL(DeepLink.openQuote(script: entry.script, mode: entry.widgetMode).url)
    }
}

// MARK: - Small Widget (Runic text only)

struct SmallWidgetView: View {
    let entry: RunicQuoteEntry

    private var palette: AppThemePalette { entry.theme.palette }

    var body: some View {
        ZStack {
            // Background gradient
            backgroundGradient

            // Content
            VStack(spacing: 8) {
                Spacer()

                // Runic text (truncated)
                Text(entry.quote.runicText(for: entry.script))
                    .font(.custom(fontName, size: 20))
                    .foregroundColor(palette.primaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(4)
                    .minimumScaleFactor(0.7)

                Spacer()

                // Script indicator
                scriptIndicator
            }
            .padding()
        }
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: palette.widgetBackgroundGradient,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var scriptIndicator: some View {
        Text(entry.script.displayName)
            .font(.caption2)
            .foregroundColor(palette.tertiaryText)
    }

    private var fontName: String {
        RunicFontConfiguration.fontName(for: entry.script, font: entry.font)
    }
}

// MARK: - Medium Widget (Runic + Latin)

struct MediumWidgetView: View {
    let entry: RunicQuoteEntry

    private var palette: AppThemePalette { entry.theme.palette }

    var body: some View {
        ZStack {
            // Background gradient
            backgroundGradient

            // Glass card effect
            RoundedRectangle(cornerRadius: 0)
                .fill(.ultraThinMaterial)
                .opacity(0.2)

            // Content
            HStack(spacing: 16) {
                // Runic text
                VStack(alignment: .center, spacing: 8) {
                    Text(entry.quote.runicText(for: entry.script))
                        .font(.custom(fontName, size: 24))
                        .foregroundColor(palette.primaryText)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .minimumScaleFactor(0.6)
                        .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: .infinity)

                // Divider
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, palette.divider, .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 1)

                // Latin text + author
                VStack(alignment: .leading, spacing: 8) {
                    Text(entry.quote.textLatin)
                        .font(.caption)
                        .foregroundColor(palette.secondaryText)
                        .lineLimit(3)
                        .minimumScaleFactor(0.8)

                    Spacer()

                    Text("— \(entry.quote.author)")
                        .font(.caption2)
                        .foregroundColor(palette.tertiaryText)
                        .italic()
                        .lineLimit(1)

                    scriptIndicator
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
        }
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: palette.widgetBackgroundGradient,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var scriptIndicator: some View {
        Text(entry.script.displayName)
            .font(.caption2)
            .foregroundColor(palette.tertiaryText)
    }

    private var fontName: String {
        RunicFontConfiguration.fontName(for: entry.script, font: entry.font)
    }
}

// MARK: - Large Widget (Full quote display)

struct LargeWidgetView: View {
    let entry: RunicQuoteEntry

    private var palette: AppThemePalette { entry.theme.palette }

    var body: some View {
        ZStack {
            // Background gradient
            backgroundGradient

            // Glass overlay
            RoundedRectangle(cornerRadius: 0)
                .fill(.ultraThinMaterial)
                .opacity(0.15)

            // Content
            VStack(spacing: 20) {
                // Header
                HStack {
                    Text(entry.script.displayName)
                        .font(.headline)
                        .foregroundColor(palette.secondaryText)

                    Spacer()

                    Text(entry.widgetMode.displayName)
                        .font(.caption)
                        .foregroundColor(palette.tertiaryText)
                }

                Spacer()

                // Runic text (large)
                Text(entry.quote.runicText(for: entry.script))
                    .font(.custom(fontName, size: 32))
                    .foregroundColor(palette.primaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(6)
                    .minimumScaleFactor(0.6)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.thinMaterial)
                            .opacity(0.3)
                    )

                // Divider
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, palette.divider, .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1)
                    .padding(.horizontal, 40)

                // Latin text
                Text(entry.quote.textLatin)
                    .font(.body)
                    .foregroundColor(palette.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(4)

                // Author
                Text("— \(entry.quote.author)")
                    .font(.callout)
                    .foregroundColor(palette.tertiaryText)
                    .italic()

                Spacer()
            }
            .padding()
        }
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: palette.widgetBackgroundGradient,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var fontName: String {
        RunicFontConfiguration.fontName(for: entry.script, font: entry.font)
    }
}

// MARK: - Lock Screen Widgets

/// Circular widget for Lock Screen
struct CircularWidgetView: View {
    let entry: RunicQuoteEntry

    var body: some View {
        ZStack {
            // Single runic character
            Text(String(entry.quote.runicText(for: entry.script).prefix(1)))
                .font(.custom(fontName, size: 24))
                .fontWeight(.bold)
        }
    }

    private var fontName: String {
        RunicFontConfiguration.fontName(for: entry.script, font: entry.font)
    }
}

/// Rectangular widget for Lock Screen
struct RectangularWidgetView: View {
    let entry: RunicQuoteEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Runic text (truncated)
            Text(entry.quote.runicText(for: entry.script))
                .font(.custom(fontName, size: 14))
                .fontWeight(.medium)
                .lineLimit(1)

            // Author
            Text("— \(entry.quote.author)")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    private var fontName: String {
        RunicFontConfiguration.fontName(for: entry.script, font: entry.font)
    }
}

/// Inline widget for Lock Screen
struct InlineWidgetView: View {
    let entry: RunicQuoteEntry

    var body: some View {
        Text(entry.quote.runicText(for: entry.script))
            .font(.custom(fontName, size: 12))
    }

    private var fontName: String {
        RunicFontConfiguration.fontName(for: entry.script, font: entry.font)
    }
}

// MARK: - Previews

#Preview(as: .systemSmall) {
    RunicQuoteWidget()
} timeline: {
    RunicQuoteEntry.placeholder()
}

#Preview(as: .systemMedium) {
    RunicQuoteWidget()
} timeline: {
    RunicQuoteEntry.placeholder()
}

#Preview(as: .systemLarge) {
    RunicQuoteWidget()
} timeline: {
    RunicQuoteEntry.placeholder()
}

#Preview(as: .accessoryCircular) {
    RunicQuoteWidget()
} timeline: {
    RunicQuoteEntry.placeholder()
}

#Preview(as: .accessoryRectangular) {
    RunicQuoteWidget()
} timeline: {
    RunicQuoteEntry.placeholder()
}
