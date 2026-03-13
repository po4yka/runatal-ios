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
        ContentPlate(
            palette: palette,
            tone: contentTone,
            cornerRadius: cornerRadius,
            shadowRadius: shadowRadius,
            contentPadding: contentPadding
        ) {
            content
        }
    }

    private var contentTone: ContentPlateTone {
        switch tone {
        case .hero:
            return .hero
        case .primary:
            return .primary
        case .secondary:
            return .secondary
        }
    }
}
