//
//  EditorialEmptyState.swift
//  RunicQuotes
//
//  Created by Codex on 2026-03-13.
//

import SwiftUI

struct EditorialEmptyState: View {
    let palette: AppThemePalette
    let icon: String
    let eyebrow: String?
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?

    init(
        palette: AppThemePalette,
        icon: String,
        eyebrow: String? = nil,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.palette = palette
        self.icon = icon
        self.eyebrow = eyebrow
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        EditorialCard(
            palette: palette,
            tone: .secondary,
            cornerRadius: DesignTokens.CornerRadius.xl,
            shadowRadius: DesignTokens.Elevation.low
        ) {
            VStack(spacing: DesignTokens.Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(palette.accent)

                if let eyebrow {
                    SectionLabel(title: eyebrow, palette: palette)
                }

                Text(title)
                    .font(DesignTokens.Typography.sectionTitle)
                    .foregroundStyle(palette.textPrimary)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(DesignTokens.Typography.callout)
                    .foregroundStyle(palette.textSecondary)
                    .multilineTextAlignment(.center)

                if let actionTitle, let action {
                    GlassButton.primary(actionTitle, icon: nil, hapticTier: nil, action: action)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}
