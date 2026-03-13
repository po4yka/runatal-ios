//
//  LiquidProminentButtonStyle.swift
//  RunicQuotes
//
//  Created by Codex on 2026-03-13.
//

import SwiftUI

struct LiquidProminentButtonStyle: ButtonStyle {
    let palette: AppThemePalette
    let emphasized: Bool

    func makeBody(configuration: Configuration) -> some View {
        LiquidProminentButtonBody(
            configuration: configuration,
            palette: palette,
            emphasized: emphasized
        )
    }
}

private struct LiquidProminentButtonBody: View {
    let configuration: ButtonStyle.Configuration
    let palette: AppThemePalette
    let emphasized: Bool

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        let shape = Capsule(style: .continuous)

        configuration.label
            .font(DesignTokens.Typography.toolbarLabel)
            .foregroundStyle(emphasized ? palette.background : palette.textPrimary)
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.vertical, DesignTokens.Spacing.sm)
            .background {
                if reduceTransparency {
                    shape.fill(emphasized ? palette.accent : palette.chromeFallback)
                } else if emphasized {
                    Color.clear
                        .glassEffect(.regular.tint(palette.accent).interactive(), in: shape)
                } else {
                    Color.clear
                        .glassEffect(.clear.tint(palette.chromeTint).interactive(), in: shape)
                }
            }
            .overlay {
                shape
                    .strokeBorder(
                        emphasized ? palette.strongCardStroke : palette.chromeStroke,
                        lineWidth: DesignTokens.Stroke.hairline
                    )
            }
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.14), value: configuration.isPressed)
    }
}
