//
//  LiquidCard.swift
//  RunicQuotes
//
//  Created by Codex on 2026-03-13.
//

import SwiftUI

enum ContentPlateTone {
    case hero
    case primary
    case secondary
}

struct ContentPlate<Content: View>: View {
    let palette: AppThemePalette
    let tone: ContentPlateTone
    let cornerRadius: CGFloat
    let shadowRadius: CGFloat
    let contentPadding: CGFloat
    let content: Content

    init(
        palette: AppThemePalette,
        tone: ContentPlateTone = .primary,
        cornerRadius: CGFloat = DesignTokens.CornerRadius.xl,
        shadowRadius: CGFloat = DesignTokens.Elevation.medium,
        contentPadding: CGFloat = DesignTokens.Spacing.md,
        @ViewBuilder content: () -> Content
    ) {
        self.palette = palette
        self.tone = tone
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
        self.contentPadding = contentPadding
        self.content = content()
    }

    var body: some View {
        content
            .padding(contentPadding)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(backgroundFill)
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(strokeColor, lineWidth: strokeWidth)
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [palette.highlight, .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .allowsHitTesting(false)
            }
            .shadow(color: palette.shadowColor, radius: shadowRadius, x: 0, y: tone == .hero ? 12 : 6)
    }

    private var backgroundFill: some ShapeStyle {
        switch tone {
        case .hero:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [palette.contentPlateElevated, palette.contentPlate],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case .primary:
            return AnyShapeStyle(palette.contentPlate)
        case .secondary:
            return AnyShapeStyle(palette.insetPlate)
        }
    }

    private var strokeColor: Color {
        switch tone {
        case .hero:
            return palette.strongCardStroke
        case .primary:
            return palette.contentStroke
        case .secondary:
            return palette.contentStroke.opacity(0.8)
        }
    }

    private var strokeWidth: CGFloat {
        tone == .hero ? DesignTokens.Stroke.emphasis : DesignTokens.Stroke.hairline
    }
}

struct LiquidCard<Content: View>: View {
    let palette: AppThemePalette
    let role: LiquidSurfaceRole
    let cornerRadius: CGFloat
    let shadowRadius: CGFloat
    let contentPadding: CGFloat
    let isNested: Bool
    let interactive: Bool
    let content: Content

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    init(
        palette: AppThemePalette,
        role: LiquidSurfaceRole = .chrome,
        cornerRadius: CGFloat = DesignTokens.CornerRadius.xl,
        shadowRadius: CGFloat = DesignTokens.Elevation.chrome,
        contentPadding: CGFloat = DesignTokens.Spacing.md,
        isNested: Bool = false,
        interactive: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.palette = palette
        self.role = role
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
        self.contentPadding = contentPadding
        self.isNested = isNested
        self.interactive = interactive
        self.content = content()
    }

    var body: some View {
        let policy = LiquidEffectPolicy(
            role: role,
            reduceTransparency: reduceTransparency,
            isNested: isNested
        )
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        return content
            .padding(contentPadding)
            .background {
                if policy.shouldUseGlass {
                    Color.clear
                        .glassEffect(policy.glass(using: palette, interactive: interactive), in: shape)
                } else {
                    shape.fill(policy.fillColor(using: palette))
                }
            }
            .overlay {
                shape
                    .strokeBorder(policy.strokeColor(using: palette), lineWidth: DesignTokens.Stroke.hairline)
            }
            .overlay {
                shape
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.16), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .opacity(policy.shouldUseGlass ? 1 : 0.45)
                    .allowsHitTesting(false)
            }
            .shadow(color: palette.shadowColor.opacity(policy.shouldUseGlass ? 0.8 : 0.45), radius: shadowRadius, x: 0, y: 8)
    }
}
