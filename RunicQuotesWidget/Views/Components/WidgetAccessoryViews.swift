//
//  WidgetAccessoryViews.swift
//  RunicQuotesWidget
//
//  Created by Codex on 2026-03-13.
//

import SwiftUI

/// Circular widget for Lock Screen
struct CircularWidgetView: View {
    let entry: RunicQuoteEntry
    @Environment(\.colorScheme) private var colorScheme

    private var palette: AppThemePalette { entry.palette(for: colorScheme) }

    var body: some View {
        ZStack {
            if entry.showsDecorativeGlyphs {
                WidgetGlyphRing(glyph: entry.decorativeGlyph, palette: palette)
                    .padding(1)
            }

            Text(entry.decorativeGlyph)
                .font(.custom(entry.widgetFontName, size: 23))
                .bold()
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
                    .bold()
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

struct WidgetDecorativeBackground: View {
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

extension RunicQuoteEntry {
    func widgetBackgroundGradient(for colorScheme: ColorScheme) -> some View {
        let palette = palette(for: colorScheme)
        return LinearGradient(
            colors: palette.widgetBackgroundGradient,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    func palette(for colorScheme: ColorScheme) -> AppThemePalette {
        AppThemePalette.themed(theme, for: colorScheme)
    }

    var widgetFontName: String {
        RunicFontConfiguration.fontName(for: script, font: font)
    }

    var widgetAccessibilityLabel: String {
        "\(quote.textLatin), by \(quote.author)"
    }
}

extension RunicQuoteEntry {
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
