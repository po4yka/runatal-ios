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

    private var palette: AppThemePalette { AppThemePalette.adaptive(for: colorScheme) }

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

    private var palette: AppThemePalette { AppThemePalette.adaptive(for: colorScheme) }

    var body: some View {
        ZStack {
            entry.widgetBackgroundGradient(for: colorScheme)

            RoundedRectangle(cornerRadius: 0)
                .fill(.ultraThinMaterial)
                .opacity(0.18)

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

    private var palette: AppThemePalette { AppThemePalette.adaptive(for: colorScheme) }

    var body: some View {
        ZStack {
            entry.widgetBackgroundGradient(for: colorScheme)

            RoundedRectangle(cornerRadius: 0)
                .fill(.ultraThinMaterial)
                .opacity(0.14)

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
                        .fill(.thinMaterial)
                        .opacity(0.3)
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
                            .fill(.thinMaterial)
                            .opacity(0.32)
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

// MARK: - Lock Screen Widgets

/// Circular widget for Lock Screen
struct CircularWidgetView: View {
    let entry: RunicQuoteEntry
    @Environment(\.colorScheme) private var colorScheme

    private var palette: AppThemePalette { AppThemePalette.adaptive(for: colorScheme) }

    var body: some View {
        ZStack {
            if entry.showsDecorativeGlyphs {
                WidgetGlyphRing(glyph: entry.decorativeGlyph, palette: palette)
                    .padding(1)
            }

            Text(entry.decorativeGlyph)
                .font(.custom(entry.widgetFontName, size: 23))
                .fontWeight(.bold)
                .lineLimit(1)
        }
        .accessibilityLabel("Runic quote: \(entry.quote.textLatin)")
    }
}

/// Rectangular widget for Lock Screen
struct RectangularWidgetView: View {
    let entry: RunicQuoteEntry

    private var runicLine: String { entry.compactRunic(maxCharacters: 26) }
    private var translationLine: String { entry.compactLatin(maxCharacters: 42) }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            if entry.widgetStyle == .runeFirst {
                Text(runicLine)
                    .font(.custom(entry.widgetFontName, size: 14))
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .minimumScaleFactor(0.75)

                Text(translationLine)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            } else {
                Text(translationLine)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Text(runicLine)
                    .font(.custom(entry.widgetFontName, size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(entry.widgetAccessibilityLabel)
    }
}

/// Inline widget for Lock Screen
struct InlineWidgetView: View {
    let entry: RunicQuoteEntry

    var body: some View {
        if entry.widgetStyle == .runeFirst {
            Text("\(entry.compactRunic(maxCharacters: 13)) \u{00B7} \(entry.compactAuthor(maxCharacters: 10))")
                .font(.custom(entry.widgetFontName, size: 12))
                .lineLimit(1)
                .truncationMode(.tail)
                .accessibilityLabel(entry.widgetAccessibilityLabel)
        } else {
            Text("\(entry.compactLatin(maxCharacters: 20)) \u{00B7} \(entry.decorativeGlyph)")
                .font(.caption)
                .lineLimit(1)
                .truncationMode(.tail)
                .accessibilityLabel(entry.widgetAccessibilityLabel)
        }
    }
}

// MARK: - Decorative Elements

private struct WidgetDecorativeBackground: View {
    let glyph: String
    let palette: AppThemePalette

    private let points: [CGPoint] = [
        CGPoint(x: 0.10, y: 0.17),
        CGPoint(x: 0.25, y: 0.80),
        CGPoint(x: 0.43, y: 0.28),
        CGPoint(x: 0.58, y: 0.72),
        CGPoint(x: 0.74, y: 0.19),
        CGPoint(x: 0.88, y: 0.77)
    ]

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(Array(points.enumerated()), id: \.offset) { index, point in
                    Text(glyph)
                        .font(.system(size: 16 + CGFloat(index % 3) * 7, weight: .semibold))
                        .foregroundStyle((index.isMultiple(of: 2) ? palette.accent : palette.separator).opacity(0.16))
                        .rotationEffect(.degrees(Double(index) * 31))
                        .position(
                            x: proxy.size.width * point.x,
                            y: proxy.size.height * point.y
                        )
                }
            }
            .mask(
                LinearGradient(
                    colors: [.clear, .white, .white, .clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
        .allowsHitTesting(false)
    }
}

private struct WidgetGlyphRing: View {
    let glyph: String
    let palette: AppThemePalette

    var body: some View {
        ZStack {
            Circle()
                .stroke(palette.accent.opacity(0.42), lineWidth: 1.1)

            Circle()
                .stroke(
                    palette.separator.opacity(0.65),
                    style: StrokeStyle(lineWidth: 0.8, dash: [2.2, 3.4])
                )
                .padding(3)

            VStack {
                Text(glyph)
                Spacer()
                Text(glyph)
            }
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(palette.textTertiary.opacity(0.85))
            .padding(.vertical, 3)

            HStack {
                Text(glyph)
                Spacer()
                Text(glyph)
            }
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(palette.textTertiary.opacity(0.85))
            .padding(.horizontal, 3)
        }
    }
}

// MARK: - Shared Widget Helpers

extension RunicQuoteEntry {
    func widgetBackgroundGradient(for colorScheme: ColorScheme) -> some View {
        let palette = AppThemePalette.adaptive(for: colorScheme)
        return LinearGradient(
            colors: palette.widgetBackgroundGradient,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var widgetFontName: String {
        RunicFontConfiguration.fontName(for: script, font: font)
    }

    var widgetAccessibilityLabel: String {
        "\(quote.textLatin), by \(quote.author)"
    }
}

// MARK: - Compact Text Helpers

private extension RunicQuoteEntry {
    var decorativeGlyph: String {
        switch script {
        case .elder, .younger:
            return "\u{16A0}"
        case .cirth:
            return "\u{2E38}"
        }
    }

    func compactRunic(maxCharacters: Int) -> String {
        quote.runicText(for: script).widgetCompact(maxCharacters: maxCharacters)
    }

    func compactLatin(maxCharacters: Int) -> String {
        quote.textLatin.widgetCompact(maxCharacters: maxCharacters)
    }

    func compactAuthor(maxCharacters: Int) -> String {
        quote.author.widgetCompact(maxCharacters: maxCharacters)
    }
}

private extension String {
    func widgetCompact(maxCharacters: Int) -> String {
        let collapsed = replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard collapsed.count > maxCharacters, maxCharacters > 1 else {
            return collapsed
        }

        let cutoff = collapsed.index(collapsed.startIndex, offsetBy: maxCharacters - 1)
        return String(collapsed[..<cutoff]).trimmingCharacters(in: .whitespaces) + "\u{2026}"
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
