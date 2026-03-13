//
//  FeedbackBanner.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import SwiftUI

struct FeedbackBanner: View {
    enum Tone {
        case success
        case warning
        case error
    }

    let palette: AppThemePalette
    let tone: Tone
    let title: String
    let message: String

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            Image(systemName: self.symbolName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(self.symbolColor)
                .frame(width: 28, height: 28)
                .background {
                    Circle()
                        .fill(self.symbolColor.opacity(0.12))
                }

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                Text(self.title)
                    .font(DesignTokens.Typography.controlLabel)
                    .foregroundStyle(self.palette.textPrimary)

                Text(self.message)
                    .font(DesignTokens.Typography.listMeta)
                    .foregroundStyle(self.palette.textSecondary)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.vertical, DesignTokens.Spacing.sm)
        .background {
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                .fill(self.backgroundFill)
        }
        .overlay {
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                .strokeBorder(self.symbolColor.opacity(0.2), lineWidth: DesignTokens.Stroke.hairline)
        }
    }

    private var symbolName: String {
        switch self.tone {
        case .success:
            "checkmark.circle.fill"
        case .warning:
            "exclamationmark.triangle.fill"
        case .error:
            "xmark.octagon.fill"
        }
    }

    private var symbolColor: Color {
        switch self.tone {
        case .success:
            self.palette.success
        case .warning:
            self.palette.warning
        case .error:
            self.palette.error
        }
    }

    private var backgroundFill: Color {
        switch self.tone {
        case .success:
            self.palette.successFill.opacity(0.85)
        case .warning:
            self.palette.warningFill.opacity(0.85)
        case .error:
            self.palette.errorFill.opacity(0.92)
        }
    }
}
