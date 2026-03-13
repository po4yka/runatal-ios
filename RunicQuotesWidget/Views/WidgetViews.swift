//
//  WidgetViews.swift
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

// MARK: - Small Widget

struct SmallWidgetView: View {
    let entry: RunicQuoteEntry
    @Environment(\.colorScheme) private var colorScheme

    private var palette: AppThemePalette { entry.palette(for: colorScheme) }

    var body: some View {
        ZStack {
            entry.widgetBackgroundGradient(for: colorScheme)

            if entry.showsDecorativeGlyphs {
                WidgetDecorativeBackground(glyph: entry.decorativeGlyph, palette: palette)
                    .opacity(0.8)
            }

            content
                .padding(DesignTokens.Spacing.md)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(entry.widgetAccessibilityLabel)
    }

    @ViewBuilder
    private var content: some View {
        switch entry.widgetStyle {
        case .runeFirst:
            VStack(spacing: DesignTokens.Spacing.xs) {
                Spacer(minLength: 0)

                Text(entry.compactRunic(maxCharacters: 46))
                    .font(.custom(entry.widgetFontName, size: 20))
                    .foregroundStyle(palette.runeText)
                    .multilineTextAlignment(.center)
                    .lineLimit(4)
                    .minimumScaleFactor(0.65)

                Text(entry.compactLatin(maxCharacters: 58))
                    .font(.caption2)
                    .foregroundStyle(palette.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                Spacer(minLength: 0)
                widgetScriptIndicator
            }
        case .translationFirst:
            VStack(spacing: DesignTokens.Spacing.xs) {
                Spacer(minLength: 0)

                Text(entry.compactLatin(maxCharacters: 86))
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(palette.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(4)
                    .minimumScaleFactor(0.75)

                Rectangle()
                    .fill(palette.separator)
                    .frame(height: 1)

                Text(entry.compactRunic(maxCharacters: 34))
                    .font(.custom(entry.widgetFontName, size: 15))
                    .foregroundStyle(palette.runeText)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                Spacer(minLength: 0)
                widgetScriptIndicator
            }
        }
    }

    private var widgetScriptIndicator: some View {
        Text(entry.script.displayName)
            .font(.caption2)
            .foregroundStyle(palette.textTertiary)
    }
}

// MARK: - Medium Widget

struct MediumWidgetView: View {
    let entry: RunicQuoteEntry
    @Environment(\.colorScheme) private var colorScheme

    private var palette: AppThemePalette { entry.palette(for: colorScheme) }

    var body: some View {
        ZStack {
            entry.widgetBackgroundGradient(for: colorScheme)

            RoundedRectangle(cornerRadius: 0)
                .fill(palette.bannerBackground)
                .opacity(0.9)

            if entry.showsDecorativeGlyphs {
                WidgetDecorativeBackground(glyph: entry.decorativeGlyph, palette: palette)
                    .opacity(0.75)
            }

            content
                .padding(DesignTokens.Spacing.lg)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(entry.widgetAccessibilityLabel)
    }

    @ViewBuilder
    private var content: some View {
        switch entry.widgetStyle {
        case .runeFirst:
            VStack(spacing: DesignTokens.Spacing.xs) {
                HStack {
                    Text(entry.compactRunic(maxCharacters: 18))
                        .font(.custom(entry.widgetFontName, size: 12))
                        .foregroundStyle(palette.runeText)
                        .lineLimit(1)

                    Spacer()

                    Text("Quote of the Day")
                        .font(.caption2)
                        .foregroundStyle(palette.textTertiary)
                }

                Spacer(minLength: 0)

                Text(entry.compactLatin(maxCharacters: 128))
                    .font(.body)
                    .foregroundStyle(palette.textPrimary)
                    .lineLimit(3)
                    .minimumScaleFactor(0.8)

                Text(entry.compactAuthor(maxCharacters: 30))
                    .font(.caption)
                    .foregroundStyle(palette.textSecondary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

        case .translationFirst:
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                Text(entry.compactLatin(maxCharacters: 128))
                    .font(.body.weight(.semibold))
                    .foregroundStyle(palette.textPrimary)
                    .lineLimit(3)
                    .minimumScaleFactor(0.8)

                HStack(spacing: DesignTokens.Spacing.xs) {
                    Text("\u{2014} \(entry.compactAuthor(maxCharacters: 26))")
                        .font(.caption2)
                        .foregroundStyle(palette.textTertiary)
                        .lineLimit(1)

                    Spacer()

                    Text(entry.script.displayName)
                        .font(.caption2)
                        .foregroundStyle(palette.textTertiary)
                }

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, palette.separator, .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1)

                Text(entry.compactRunic(maxCharacters: 58))
                    .font(.custom(entry.widgetFontName, size: 16))
                    .foregroundStyle(palette.runeText)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
            }
        }
    }
}

// MARK: - Large Widget

struct LargeWidgetView: View {
    let entry: RunicQuoteEntry
    @Environment(\.colorScheme) private var colorScheme

    private var palette: AppThemePalette { entry.palette(for: colorScheme) }

    var body: some View {
        ZStack {
            entry.widgetBackgroundGradient(for: colorScheme)

            RoundedRectangle(cornerRadius: 0)
                .fill(palette.bannerBackground)
                .opacity(0.88)

            if entry.showsDecorativeGlyphs {
                WidgetDecorativeBackground(glyph: entry.decorativeGlyph, palette: palette)
                    .opacity(0.65)
            }

            content
                .padding(DesignTokens.Spacing.lg)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(entry.widgetAccessibilityLabel)
    }

    @ViewBuilder
    private var content: some View {
        switch entry.widgetStyle {
        case .runeFirst:
            VStack(spacing: DesignTokens.Spacing.md) {
                header

                Spacer(minLength: 0)

                VStack(spacing: DesignTokens.Spacing.xxs) {
                    Text(entry.compactRunic(maxCharacters: 40))
                        .font(.custom(entry.widgetFontName, size: 14))
                        .foregroundStyle(palette.runeText)
                        .lineLimit(1)

                    Text(entry.compactLatin(maxCharacters: 170))
                        .font(.title3)
                        .foregroundStyle(palette.textPrimary)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .minimumScaleFactor(0.8)

                    Text(entry.compactAuthor(maxCharacters: 34))
                        .font(.caption)
                        .foregroundStyle(palette.textSecondary)
                }
                    .padding(DesignTokens.Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                            .fill(palette.bannerBackground)
                    )

                Spacer(minLength: 0)

                brandingFooter
            }

        case .translationFirst:
            VStack(spacing: DesignTokens.Spacing.md) {
                header

                Spacer(minLength: 0)

                Text(entry.compactLatin(maxCharacters: 210))
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(palette.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(5)
                    .minimumScaleFactor(0.8)
                    .padding(DesignTokens.Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                            .fill(palette.bannerBackground)
                    )

                Text("\u{2014} \(entry.compactAuthor(maxCharacters: 34))")
                    .font(.callout)
                    .foregroundStyle(palette.textTertiary)
                    .italic()

                widgetDivider

                Text(entry.compactRunic(maxCharacters: 110))
                    .font(.custom(entry.widgetFontName, size: 22))
                    .foregroundStyle(palette.runeText)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.65)

                Spacer(minLength: 0)
            }
        }
    }

    private var header: some View {
        HStack {
            Text(entry.compactRunic(maxCharacters: 24))
                .font(.custom(entry.widgetFontName, size: 12))
                .foregroundStyle(palette.runeText)
                .lineLimit(1)

            Spacer()

            Text("Daily Wisdom")
                .font(.caption2)
                .foregroundStyle(palette.textTertiary)
        }
    }

    private var brandingFooter: some View {
        HStack(spacing: DesignTokens.Spacing.xxs) {
            Text(entry.decorativeGlyph)
                .font(.custom(entry.widgetFontName, size: 10))
                .foregroundStyle(palette.textTertiary)

            Text("Runic Quotes")
                .font(.caption2)
                .foregroundStyle(palette.textTertiary)
        }
    }

    private var widgetDivider: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [.clear, palette.separator, .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 1)
            .padding(.horizontal, DesignTokens.Spacing.xxl)
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
