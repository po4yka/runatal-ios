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
        // Corners only -- clear of the card area in the centre.
        let layouts: [(size: CGFloat, opacity: Double, rotation: Double, x: CGFloat, y: CGFloat)] = [
            (80, 0.018, -12, 0.05, 0.06),
            (55, 0.015, 8, 0.93, 0.04),
            (70, 0.02, -5, 0.07, 0.92),
            (45, 0.012, 14, 0.91, 0.94)
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
        .mask {
            RadialGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .clear, location: 0.25),
                    .init(color: .white.opacity(0.4), location: 0.5),
                    .init(color: .white, location: 0.72)
                ],
                center: .center,
                startRadius: 0,
                endRadius: UIScreen.main.bounds.height * 0.55
            )
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
