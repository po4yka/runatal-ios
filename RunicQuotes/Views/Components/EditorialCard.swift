//
//  EditorialCard.swift
//  RunicQuotes
//
//  Created by Codex on 2026-03-13.
//

import SwiftUI

enum EditorialCardTone {
    case hero
    case primary
    case secondary
}

struct EditorialCard<Content: View>: View {
    let palette: AppThemePalette
    let tone: EditorialCardTone
    let cornerRadius: CGFloat
    let shadowRadius: CGFloat
    let contentPadding: CGFloat
    let content: Content

    init(
        palette: AppThemePalette,
        tone: EditorialCardTone = .primary,
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
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(backgroundStyle)
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(strokeColor, lineWidth: strokeWidth)
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [palette.highlight, .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                    .allowsHitTesting(false)
            }
            .shadow(color: palette.shadowColor, radius: shadowRadius, x: 0, y: shadowYOffset)
    }

    private var backgroundStyle: some ShapeStyle {
        switch tone {
        case .hero:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [palette.editorialSurface, palette.editorialInset],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case .primary:
            return AnyShapeStyle(palette.editorialSurface)
        case .secondary:
            return AnyShapeStyle(palette.editorialMutedSurface)
        }
    }

    private var strokeColor: Color {
        switch tone {
        case .hero:
            return palette.strongCardStroke
        case .primary:
            return palette.cardStroke
        case .secondary:
            return palette.cardStroke.opacity(0.75)
        }
    }

    private var strokeWidth: CGFloat {
        tone == .hero ? DesignTokens.Stroke.emphasis : DesignTokens.Stroke.hairline
    }

    private var shadowYOffset: CGFloat {
        tone == .hero ? 12 : 6
    }
}
