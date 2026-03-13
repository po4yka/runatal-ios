//
//  EditorialEmptyState.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
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
        action: (() -> Void)? = nil,
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
        ContentPlate(
            palette: self.palette,
            tone: .secondary,
            cornerRadius: DesignTokens.CornerRadius.xl,
            shadowRadius: 0,
        ) {
            VStack(spacing: DesignTokens.Spacing.md) {
                Image(systemName: self.icon)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(self.palette.accent)

                if let eyebrow {
                    SectionLabel(title: eyebrow, palette: self.palette)
                }

                Text(self.title)
                    .font(DesignTokens.Typography.sectionTitle)
                    .foregroundStyle(self.palette.textPrimary)
                    .multilineTextAlignment(.center)

                Text(self.message)
                    .font(DesignTokens.Typography.supportingBody)
                    .foregroundStyle(self.palette.textSecondary)
                    .multilineTextAlignment(.center)

                if let actionTitle, let action {
                    Button(action: action) {
                        Text(actionTitle)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(LiquidProminentButtonStyle(palette: self.palette, emphasized: true))
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}
