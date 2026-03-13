//
//  QuoteErrorView.swift
//  RunicQuotes
//
//  Created by Codex on 2026-03-13.
//

import SwiftUI

struct QuoteErrorView: View {
    let message: String
    let palette: AppThemePalette
    let retry: () -> Void

    var body: some View {
        ContentPlate(
            palette: palette,
            tone: .secondary,
            cornerRadius: DesignTokens.CornerRadius.xl,
            shadowRadius: 0,
            contentPadding: DesignTokens.Spacing.md
        ) {
            VStack(spacing: DesignTokens.Spacing.md) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(palette.error.opacity(0.8))
                    .accessibilityLabel("Error")

                Text("Error")
                    .font(.headline)
                    .foregroundStyle(palette.textPrimary)

                Text(message)
                    .font(DesignTokens.Typography.supportingBody)
                    .foregroundStyle(palette.textSecondary)
                    .multilineTextAlignment(.center)

                Button(action: retry) {
                    Label("Try Again", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(LiquidProminentButtonStyle(palette: palette, emphasized: true))
                .accessibilityLabel("Retry loading quote")
                .accessibilityHint("Double tap to try loading the quote again")
                .accessibilityIdentifier("quote_retry_button")
            }
        }
        .padding(DesignTokens.Spacing.md)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("quote_error_view")
    }
}
