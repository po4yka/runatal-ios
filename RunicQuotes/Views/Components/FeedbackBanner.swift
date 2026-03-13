//
//  FeedbackBanner.swift
//  RunicQuotes
//
//  Created by Codex on 2026-03-13.
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
            Image(systemName: symbolName)
                .foregroundStyle(symbolColor)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(palette.textPrimary)

                Text(message)
                    .font(.caption)
                    .foregroundStyle(palette.textSecondary)
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.vertical, DesignTokens.Spacing.sm)
        .background {
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                .fill(backgroundFill)
        }
        .overlay {
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                .strokeBorder(symbolColor.opacity(0.2), lineWidth: DesignTokens.Stroke.hairline)
        }
    }

    private var symbolName: String {
        switch tone {
        case .success:
            return "checkmark.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .error:
            return "xmark.octagon.fill"
        }
    }

    private var symbolColor: Color {
        switch tone {
        case .success:
            return palette.success
        case .warning:
            return palette.warning
        case .error:
            return palette.error
        }
    }

    private var backgroundFill: Color {
        switch tone {
        case .success:
            return palette.successFill
        case .warning:
            return palette.warningFill
        case .error:
            return palette.errorFill
        }
    }
}
