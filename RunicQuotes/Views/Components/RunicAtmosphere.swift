//
//  RunicAtmosphere.swift
//  RunicQuotes
//

import SwiftUI

/// Faint decorative rune glyphs scattered at screen edges for atmospheric depth.
struct RunicAtmosphere: View {
    let script: RunicScript

    private struct GlyphLayout {
        let size: CGFloat
        let opacity: Double
        let rotation: Double
        let x: CGFloat
        let y: CGFloat
    }

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
        let layouts = [
            GlyphLayout(size: 80, opacity: 0.018, rotation: -12, x: 0.05, y: 0.06),
            GlyphLayout(size: 55, opacity: 0.015, rotation: 8, x: 0.93, y: 0.04),
            GlyphLayout(size: 70, opacity: 0.02, rotation: -5, x: 0.07, y: 0.92),
            GlyphLayout(size: 45, opacity: 0.012, rotation: 14, x: 0.91, y: 0.94)
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
            ZStack {
                ForEach(glyphs) { glyph in
                    Text(glyph.character)
                        .font(.system(size: glyph.size))
                        .foregroundStyle(.white)
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
                    endRadius: proxy.size.height * 0.55
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
