//
//  RunicTipViewStyle.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import SwiftUI
import TipKit

struct RunicTipViewStyle: TipViewStyle {
    let palette: AppThemePalette

    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .top, spacing: DesignTokens.Spacing.sm) {
            if let image = configuration.image {
                image
                    .foregroundStyle(self.palette.accent)
                    .font(.title3)
                    .padding(.top, 2)
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                if let title = configuration.title {
                    title
                        .font(DesignTokens.Typography.bodyEmphasis)
                        .foregroundStyle(self.palette.textPrimary)
                }

                if let message = configuration.message {
                    message
                        .font(DesignTokens.Typography.callout)
                        .foregroundStyle(self.palette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: DesignTokens.Spacing.xs)
        }
        .padding(DesignTokens.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                .fill(self.palette.editorialSurface)
        }
        .overlay {
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                .stroke(self.palette.cardStroke, lineWidth: DesignTokens.Stroke.hairline)
        }
    }
}
