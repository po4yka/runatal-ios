//
//  WidgetViews.swift
//  RunicQuotes
//
//  Created by Claude on 09.10.25.
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
            switch self.widgetFamily {
            case .systemSmall:
                SmallWidgetView(entry: self.entry)
            case .systemMedium:
                MediumWidgetView(entry: self.entry)
            case .systemLarge:
                LargeWidgetView(entry: self.entry)
            case .accessoryCircular:
                CircularWidgetView(entry: self.entry)
            case .accessoryRectangular:
                RectangularWidgetView(entry: self.entry)
            case .accessoryInline:
                InlineWidgetView(entry: self.entry)
            default:
                SmallWidgetView(entry: self.entry)
            }
        }
        .widgetURL(DeepLink.openQuote(script: self.entry.script, mode: self.entry.widgetMode).url)
    }
}

// MARK: - Small Widget

struct SmallWidgetView: View {
    let entry: RunicQuoteEntry
    @Environment(\.colorScheme) private var colorScheme

    private var palette: AppThemePalette {
        self.entry.palette(for: self.colorScheme)
    }

    var body: some View {
        ZStack {
            self.entry.widgetBackgroundGradient(for: self.colorScheme)

            if self.entry.showsDecorativeGlyphs {
                WidgetDecorativeBackground(glyph: self.entry.decorativeGlyph, palette: self.palette)
                    .opacity(0.42)
            }

            self.content
                .padding(DesignTokens.Spacing.md)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(self.entry.widgetAccessibilityLabel)
    }

    @ViewBuilder
    private var content: some View {
        switch self.entry.widgetStyle {
        case .runeFirst:
            VStack(spacing: DesignTokens.Spacing.xs) {
                Spacer(minLength: 0)

                Text(self.entry.compactRunic(maxCharacters: 46))
                    .font(.custom(self.entry.widgetFontName, size: 20))
                    .foregroundStyle(self.palette.runeText)
                    .multilineTextAlignment(.center)
                    .lineLimit(4)
                    .minimumScaleFactor(0.65)

                Text(self.entry.compactLatin(maxCharacters: 58))
                    .font(DesignTokens.Typography.widgetMeta)
                    .foregroundStyle(self.palette.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                Spacer(minLength: 0)
                self.widgetScriptIndicator
            }
        case .translationFirst:
            VStack(spacing: DesignTokens.Spacing.xs) {
                Spacer(minLength: 0)

                Text(self.entry.compactLatin(maxCharacters: 86))
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(self.palette.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(4)
                    .minimumScaleFactor(0.75)

                Rectangle()
                    .fill(self.palette.separator)
                    .frame(height: 1)

                Text(self.entry.compactRunic(maxCharacters: 34))
                    .font(.custom(self.entry.widgetFontName, size: 15))
                    .foregroundStyle(self.palette.runeText)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                Spacer(minLength: 0)
                self.widgetScriptIndicator
            }
        }
    }

    private var widgetScriptIndicator: some View {
        Text(self.entry.script.displayName)
            .font(DesignTokens.Typography.widgetMeta)
            .foregroundStyle(self.palette.textTertiary)
    }
}

// MARK: - Medium Widget

struct MediumWidgetView: View {
    let entry: RunicQuoteEntry
    @Environment(\.colorScheme) private var colorScheme

    private var palette: AppThemePalette {
        self.entry.palette(for: self.colorScheme)
    }

    var body: some View {
        ZStack {
            self.entry.widgetBackgroundGradient(for: self.colorScheme)

            RoundedRectangle(cornerRadius: 0)
                .fill(self.palette.rowFill)
                .opacity(0.45)

            if self.entry.showsDecorativeGlyphs {
                WidgetDecorativeBackground(glyph: self.entry.decorativeGlyph, palette: self.palette)
                    .opacity(0.32)
            }

            self.content
                .padding(DesignTokens.Spacing.lg)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(self.entry.widgetAccessibilityLabel)
    }

    @ViewBuilder
    private var content: some View {
        switch self.entry.widgetStyle {
        case .runeFirst:
            VStack(spacing: DesignTokens.Spacing.xs) {
                HStack {
                    Text(self.entry.compactRunic(maxCharacters: 18))
                        .font(.custom(self.entry.widgetFontName, size: 12))
                        .foregroundStyle(self.palette.runeText)
                        .lineLimit(1)

                    Spacer()

                    Text("Quote of the Day")
                        .font(DesignTokens.Typography.widgetMeta)
                        .foregroundStyle(self.palette.textTertiary)
                }

                Spacer(minLength: 0)

                Text(self.entry.compactLatin(maxCharacters: 128))
                    .font(.body)
                    .foregroundStyle(self.palette.textPrimary)
                    .lineLimit(3)
                    .minimumScaleFactor(0.8)

                Text(self.entry.compactAuthor(maxCharacters: 30))
                    .font(.caption)
                    .foregroundStyle(self.palette.textSecondary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

        case .translationFirst:
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                Text(self.entry.compactLatin(maxCharacters: 128))
                    .font(.body.weight(.semibold))
                    .foregroundStyle(self.palette.textPrimary)
                    .lineLimit(3)
                    .minimumScaleFactor(0.8)

                HStack(spacing: DesignTokens.Spacing.xs) {
                    Text("\u{2014} \(self.entry.compactAuthor(maxCharacters: 26))")
                        .font(DesignTokens.Typography.widgetMeta)
                        .foregroundStyle(self.palette.textTertiary)
                        .lineLimit(1)

                    Spacer()

                    Text(self.entry.script.displayName)
                        .font(DesignTokens.Typography.widgetMeta)
                        .foregroundStyle(self.palette.textTertiary)
                }

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, self.palette.separator, .clear],
                            startPoint: .leading,
                            endPoint: .trailing,
                        ),
                    )
                    .frame(height: 1)

                Text(self.entry.compactRunic(maxCharacters: 58))
                    .font(.custom(self.entry.widgetFontName, size: 16))
                    .foregroundStyle(self.palette.runeText)
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

    private var palette: AppThemePalette {
        self.entry.palette(for: self.colorScheme)
    }

    var body: some View {
        ZStack {
            self.entry.widgetBackgroundGradient(for: self.colorScheme)

            RoundedRectangle(cornerRadius: 0)
                .fill(self.palette.rowFill)
                .opacity(0.42)

            if self.entry.showsDecorativeGlyphs {
                WidgetDecorativeBackground(glyph: self.entry.decorativeGlyph, palette: self.palette)
                    .opacity(0.28)
            }

            self.content
                .padding(DesignTokens.Spacing.lg)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(self.entry.widgetAccessibilityLabel)
    }

    @ViewBuilder
    private var content: some View {
        switch self.entry.widgetStyle {
        case .runeFirst:
            VStack(spacing: DesignTokens.Spacing.md) {
                self.header

                Spacer(minLength: 0)

                VStack(spacing: DesignTokens.Spacing.xxs) {
                    Text(self.entry.compactRunic(maxCharacters: 40))
                        .font(.custom(self.entry.widgetFontName, size: 14))
                        .foregroundStyle(self.palette.runeText)
                        .lineLimit(1)

                    Text(self.entry.compactLatin(maxCharacters: 170))
                        .font(.title3)
                        .foregroundStyle(self.palette.textPrimary)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .minimumScaleFactor(0.8)

                    Text(self.entry.compactAuthor(maxCharacters: 34))
                        .font(.caption)
                        .foregroundStyle(self.palette.textSecondary)
                }
                .padding(DesignTokens.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                        .fill(self.palette.bannerBackground),
                )

                Spacer(minLength: 0)

                self.brandingFooter
            }

        case .translationFirst:
            VStack(spacing: DesignTokens.Spacing.md) {
                self.header

                Spacer(minLength: 0)

                Text(self.entry.compactLatin(maxCharacters: 210))
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(self.palette.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(5)
                    .minimumScaleFactor(0.8)
                    .padding(DesignTokens.Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                            .fill(self.palette.bannerBackground),
                    )

                Text("\u{2014} \(self.entry.compactAuthor(maxCharacters: 34))")
                    .font(.callout)
                    .foregroundStyle(self.palette.textTertiary)
                    .italic()

                self.widgetDivider

                Text(self.entry.compactRunic(maxCharacters: 110))
                    .font(.custom(self.entry.widgetFontName, size: 22))
                    .foregroundStyle(self.palette.runeText)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.65)

                Spacer(minLength: 0)
            }
        }
    }

    private var header: some View {
        HStack {
            Text(self.entry.compactRunic(maxCharacters: 24))
                .font(.custom(self.entry.widgetFontName, size: 12))
                .foregroundStyle(self.palette.runeText)
                .lineLimit(1)

            Spacer()

            Text("Daily Wisdom")
                .font(DesignTokens.Typography.widgetMeta)
                .foregroundStyle(self.palette.textTertiary)
        }
    }

    private var brandingFooter: some View {
        HStack(spacing: DesignTokens.Spacing.xxs) {
            Text(self.entry.decorativeGlyph)
                .font(.custom(self.entry.widgetFontName, size: 10))
                .foregroundStyle(self.palette.textTertiary)

            Text("Runic Quotes")
                .font(DesignTokens.Typography.widgetMeta)
                .foregroundStyle(self.palette.textTertiary)
        }
    }

    private var widgetDivider: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [.clear, self.palette.separator, .clear],
                    startPoint: .leading,
                    endPoint: .trailing,
                ),
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
