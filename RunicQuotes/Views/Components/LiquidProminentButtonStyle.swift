//
//  LiquidProminentButtonStyle.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import SwiftUI

struct LiquidProminentButtonStyle: ButtonStyle {
    let palette: AppThemePalette
    let emphasized: Bool

    func makeBody(configuration: Configuration) -> some View {
        LiquidProminentButtonBody(
            configuration: configuration,
            palette: self.palette,
            emphasized: self.emphasized,
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

        self.configuration.label
            .font(DesignTokens.Typography.toolbarLabel)
            .foregroundStyle(self.emphasized ? self.palette.background : self.palette.textPrimary)
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.vertical, DesignTokens.Spacing.sm)
            .background {
                if self.reduceTransparency {
                    shape.fill(self.emphasized ? self.palette.accent : self.palette.chromeFallback)
                } else if self.emphasized {
                    Color.clear
                        .glassEffect(.regular.tint(self.palette.accent).interactive(), in: shape)
                } else {
                    Color.clear
                        .glassEffect(.clear.tint(self.palette.chromeTint).interactive(), in: shape)
                }
            }
            .overlay {
                shape
                    .strokeBorder(
                        self.emphasized ? self.palette.strongCardStroke : self.palette.chromeStroke,
                        lineWidth: DesignTokens.Stroke.hairline,
                    )
            }
            .scaleEffect(self.configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.14), value: self.configuration.isPressed)
    }
}
