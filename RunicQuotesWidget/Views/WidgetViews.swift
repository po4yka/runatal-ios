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

// MARK: - Small Widget

struct SmallWidgetView: View {
    let entry: RunicQuoteEntry

    private var palette: AppThemePalette { entry.theme.palette }

    var body: some View {
        ZStack {
            entry.widgetBackgroundGradient

            if entry.showsDecorativeGlyphs {
                WidgetDecorativeBackground(glyph: entry.decorativeGlyph, palette: palette)
                    .opacity(0.8)
            }

            content
                .padding()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(entry.widgetAccessibilityLabel)
    }

    @ViewBuilder
    private var content: some View {
        switch entry.widgetStyle {
        case .runeFirst:
            VStack(spacing: 8) {
                Spacer(minLength: 0)

                Text(entry.compactRunic(maxCharacters: 46))
                    .font(.custom(entry.widgetFontName, size: 20))
                    .foregroundStyle(palette.primaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(4)
                    .minimumScaleFactor(0.65)

                Text(entry.compactLatin(maxCharacters: 58))
                    .font(.caption2)
                    .foregroundStyle(palette.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                Spacer(minLength: 0)
                entry.widgetScriptIndicator
            }
        case .translationFirst:
            VStack(spacing: 8) {
                Spacer(minLength: 0)

                Text(entry.compactLatin(maxCharacters: 86))
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(palette.primaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(4)
                    .minimumScaleFactor(0.75)

                Divider()
                    .overlay(palette.divider)

                Text(entry.compactRunic(maxCharacters: 34))
                    .font(.custom(entry.widgetFontName, size: 15))
                    .foregroundStyle(palette.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                Spacer(minLength: 0)
                entry.widgetScriptIndicator
            }
        }
    }
}

// MARK: - Medium Widget

struct MediumWidgetView: View {
    let entry: RunicQuoteEntry

    private var palette: AppThemePalette { entry.theme.palette }

    var body: some View {
        ZStack {
            entry.widgetBackgroundGradient

            RoundedRectangle(cornerRadius: 0)
                .fill(.ultraThinMaterial)
                .opacity(0.18)

            if entry.showsDecorativeGlyphs {
                WidgetDecorativeBackground(glyph: entry.decorativeGlyph, palette: palette)
                    .opacity(0.75)
            }

            content
                .padding()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(entry.widgetAccessibilityLabel)
    }

    @ViewBuilder
    private var content: some View {
        switch entry.widgetStyle {
        case .runeFirst:
            HStack(spacing: 16) {
                VStack(alignment: .center, spacing: 8) {
                    Text(entry.compactRunic(maxCharacters: 76))
                        .font(.custom(entry.widgetFontName, size: 24))
                        .foregroundStyle(palette.primaryText)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .minimumScaleFactor(0.6)
                        .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: .infinity)

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, palette.divider, .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 1)

                VStack(alignment: .leading, spacing: 8) {
                    Text(entry.compactLatin(maxCharacters: 92))
                        .font(.caption)
                        .foregroundStyle(palette.secondaryText)
                        .lineLimit(3)
                        .minimumScaleFactor(0.8)

                    Spacer()

                    Text("\u{2014} \(entry.compactAuthor(maxCharacters: 24))")
                        .font(.caption2)
                        .foregroundStyle(palette.tertiaryText)
                        .italic()
                        .lineLimit(1)

                    entry.widgetScriptIndicator
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

        case .translationFirst:
            VStack(alignment: .leading, spacing: 10) {
                Text(entry.compactLatin(maxCharacters: 128))
                    .font(.body.weight(.semibold))
                    .foregroundStyle(palette.primaryText)
                    .lineLimit(3)
                    .minimumScaleFactor(0.8)

                HStack(spacing: 8) {
                    Text("\u{2014} \(entry.compactAuthor(maxCharacters: 26))")
                        .font(.caption2)
                        .foregroundStyle(palette.tertiaryText)
                        .lineLimit(1)

                    Spacer()

                    entry.widgetScriptIndicator
                }

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, palette.divider, .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1)

                Text(entry.compactRunic(maxCharacters: 58))
                    .font(.custom(entry.widgetFontName, size: 16))
                    .foregroundStyle(palette.secondaryText)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
            }
        }
    }
}

// MARK: - Large Widget

struct LargeWidgetView: View {
    let entry: RunicQuoteEntry

    private var palette: AppThemePalette { entry.theme.palette }

    var body: some View {
        ZStack {
            entry.widgetBackgroundGradient

            RoundedRectangle(cornerRadius: 0)
                .fill(.ultraThinMaterial)
                .opacity(0.14)

            if entry.showsDecorativeGlyphs {
                WidgetDecorativeBackground(glyph: entry.decorativeGlyph, palette: palette)
                    .opacity(0.65)
            }

            content
                .padding()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(entry.widgetAccessibilityLabel)
    }

    @ViewBuilder
    private var content: some View {
        switch entry.widgetStyle {
        case .runeFirst:
            VStack(spacing: 18) {
                header

                Spacer(minLength: 0)

                Text(entry.compactRunic(maxCharacters: 164))
                    .font(.custom(entry.widgetFontName, size: 32))
                    .foregroundStyle(palette.primaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(6)
                    .minimumScaleFactor(0.55)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.thinMaterial)
                            .opacity(0.3)
                    )

                entry.widgetDivider

                Text(entry.compactLatin(maxCharacters: 170))
                    .font(.body)
                    .foregroundStyle(palette.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(4)

                Text("\u{2014} \(entry.compactAuthor(maxCharacters: 34))")
                    .font(.callout)
                    .foregroundStyle(palette.tertiaryText)
                    .italic()

                Spacer(minLength: 0)
            }

        case .translationFirst:
            VStack(spacing: 16) {
                header

                Spacer(minLength: 0)

                Text(entry.compactLatin(maxCharacters: 210))
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(palette.primaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(5)
                    .minimumScaleFactor(0.8)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.thinMaterial)
                            .opacity(0.32)
                    )

                Text("\u{2014} \(entry.compactAuthor(maxCharacters: 34))")
                    .font(.callout)
                    .foregroundStyle(palette.tertiaryText)
                    .italic()

                entry.widgetDivider

                Text(entry.compactRunic(maxCharacters: 110))
                    .font(.custom(entry.widgetFontName, size: 22))
                    .foregroundStyle(palette.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.65)

                Spacer(minLength: 0)
            }
        }
    }

    private var header: some View {
        HStack {
            Text(entry.script.displayName)
                .font(.headline)
                .foregroundStyle(palette.secondaryText)

            Spacer()

            Text(entry.widgetMode.displayName)
                .font(.caption)
                .foregroundStyle(palette.tertiaryText)
        }
    }
}

// MARK: - Lock Screen Widgets

/// Circular widget for Lock Screen
struct CircularWidgetView: View {
    let entry: RunicQuoteEntry

    private var palette: AppThemePalette { entry.theme.palette }

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
                        .foregroundStyle((index.isMultiple(of: 2) ? palette.accent : palette.divider).opacity(0.16))
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
                    palette.divider.opacity(0.65),
                    style: StrokeStyle(lineWidth: 0.8, dash: [2.2, 3.4])
                )
                .padding(3)

            VStack {
                Text(glyph)
                Spacer()
                Text(glyph)
            }
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(palette.tertiaryText.opacity(0.85))
            .padding(.vertical, 3)

            HStack {
                Text(glyph)
                Spacer()
                Text(glyph)
            }
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(palette.tertiaryText.opacity(0.85))
            .padding(.horizontal, 3)
        }
    }
}

// MARK: - Shared Widget Helpers

extension RunicQuoteEntry {
    var widgetBackgroundGradient: some View {
        LinearGradient(
            colors: theme.palette.widgetBackgroundGradient,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var widgetFontName: String {
        RunicFontConfiguration.fontName(for: script, font: font)
    }

    var widgetScriptIndicator: some View {
        Text(script.displayName)
            .font(.caption2)
            .foregroundStyle(theme.palette.tertiaryText)
    }

    var widgetDivider: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [.clear, theme.palette.divider, .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 1)
            .padding(.horizontal, 30)
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
            return "ᚠ"
        case .cirth:
            return "⸸"
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
        return String(collapsed[..<cutoff]).trimmingCharacters(in: .whitespaces) + "…"
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
