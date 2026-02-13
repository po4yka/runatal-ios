//
//  RunicAtmosphere.swift
//  RunicQuotes
//

import SwiftUI

/// Faint decorative rune glyphs scattered at screen edges for atmospheric depth.
struct RunicAtmosphere: View {
    let script: RunicScript

    private struct PlacedGlyph: Identifiable {
        let id: Int
        let character: String
        let size: CGFloat
        let opacity: Double
        let rotation: Angle
        let alignmentX: CGFloat
        let alignmentY: CGFloat
    }

    private var glyphs: [PlacedGlyph] {
        let chars = Self.glyphCharacters(for: script)
        // Deterministic layout per script -- fixed positions at edges/corners
        let layouts: [(size: CGFloat, opacity: Double, rotation: Double, x: CGFloat, y: CGFloat)] = [
            (80, 0.03, -12, 0.05, 0.08),
            (55, 0.025, 8, 0.92, 0.05),
            (70, 0.035, -5, 0.08, 0.88),
            (45, 0.02, 14, 0.90, 0.92),
            (60, 0.03, -10, 0.04, 0.48),
            (50, 0.025, 6, 0.94, 0.52),
            (90, 0.02, -15, 0.88, 0.35),
            (65, 0.03, 11, 0.06, 0.72)
        ]

        return layouts.enumerated().map { index, layout in
            PlacedGlyph(
                id: index,
                character: chars[index % chars.count],
                size: layout.size,
                opacity: layout.opacity,
                rotation: .degrees(layout.rotation),
                alignmentX: layout.x,
                alignmentY: layout.y
            )
        }
    }

    var body: some View {
        GeometryReader { proxy in
            ForEach(glyphs) { glyph in
                Text(glyph.character)
                    .font(.system(size: glyph.size))
                    .foregroundColor(.white)
                    .opacity(glyph.opacity)
                    .rotationEffect(glyph.rotation)
                    .position(
                        x: proxy.size.width * glyph.alignmentX,
                        y: proxy.size.height * glyph.alignmentY
                    )
            }
        }
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }

    private static func glyphCharacters(for script: RunicScript) -> [String] {
        switch script {
        case .elder:
            return ["\u{16A0}", "\u{16B1}", "\u{16A6}", "\u{16B7}", "\u{16C1}", "\u{16BE}", "\u{16C7}", "\u{16AB}"]
        case .younger:
            return ["\u{16A0}", "\u{16A2}", "\u{16A6}", "\u{16B1}", "\u{16B4}", "\u{16B7}", "\u{16C1}", "\u{16C8}"]
        case .cirth:
            return ["\u{16A0}", "\u{16A6}", "\u{16B1}", "\u{16B7}", "\u{16BE}", "\u{16C1}", "\u{16C7}", "\u{16CB}"]
        }
    }
}
