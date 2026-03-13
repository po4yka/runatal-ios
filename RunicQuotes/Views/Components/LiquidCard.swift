//
//  LiquidCard.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
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
        @ViewBuilder content: () -> Content,
    ) {
        self.palette = palette
        self.tone = tone
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
        self.contentPadding = contentPadding
        self.content = content()
    }

    var body: some View {
        self.content
            .padding(self.contentPadding)
            .background {
                RoundedRectangle(cornerRadius: self.cornerRadius, style: .continuous)
                    .fill(self.backgroundFill)
            }
            .overlay {
                RoundedRectangle(cornerRadius: self.cornerRadius, style: .continuous)
                    .strokeBorder(self.strokeColor, lineWidth: self.strokeWidth)
            }
            .overlay {
                RoundedRectangle(cornerRadius: self.cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [self.palette.highlight, .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing,
                        ),
                    )
                    .allowsHitTesting(false)
            }
            .shadow(color: self.palette.shadowColor, radius: self.shadowRadius, x: 0, y: self.tone == .hero ? 12 : 6)
    }

    private var backgroundFill: some ShapeStyle {
        switch self.tone {
        case .hero:
            AnyShapeStyle(
                LinearGradient(
                    colors: [self.palette.contentPlateElevated, self.palette.contentPlate],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing,
                ),
            )
        case .primary:
            AnyShapeStyle(self.palette.contentPlate)
        case .secondary:
            AnyShapeStyle(self.palette.insetPlate)
        }
    }

    private var strokeColor: Color {
        switch self.tone {
        case .hero:
            self.palette.strongCardStroke
        case .primary:
            self.palette.contentStroke
        case .secondary:
            self.palette.contentStroke.opacity(0.8)
        }
    }

    private var strokeWidth: CGFloat {
        self.tone == .hero ? DesignTokens.Stroke.emphasis : DesignTokens.Stroke.hairline
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
        @ViewBuilder content: () -> Content,
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
            isNested: isNested,
        )
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        return self.content
            .padding(self.contentPadding)
            .background {
                if policy.shouldUseGlass {
                    Color.clear
                        .glassEffect(policy.glass(using: self.palette, interactive: self.interactive), in: shape)
                } else {
                    shape.fill(policy.fillColor(using: self.palette))
                }
            }
            .overlay {
                shape
                    .strokeBorder(policy.strokeColor(using: self.palette), lineWidth: DesignTokens.Stroke.hairline)
            }
            .overlay {
                shape
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.16), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing,
                        ),
                    )
                    .opacity(policy.shouldUseGlass ? 1 : 0.45)
                    .allowsHitTesting(false)
            }
            .shadow(color: self.palette.shadowColor.opacity(policy.shouldUseGlass ? 0.8 : 0.45), radius: self.shadowRadius, x: 0, y: 8)
    }
}
