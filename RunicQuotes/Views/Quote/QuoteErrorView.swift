//
//  QuoteErrorView.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import SwiftUI

struct QuoteErrorView: View {
    let message: String
    let palette: AppThemePalette
    let retry: () -> Void

    var body: some View {
        ContentPlate(
            palette: self.palette,
            tone: .secondary,
            cornerRadius: DesignTokens.CornerRadius.xl,
            shadowRadius: 0,
            contentPadding: DesignTokens.Spacing.md,
        ) {
            VStack(spacing: DesignTokens.Spacing.md) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(self.palette.error.opacity(0.8))
                    .accessibilityLabel("Error")

                Text("Error")
                    .font(.headline)
                    .foregroundStyle(self.palette.textPrimary)

                Text(self.message)
                    .font(DesignTokens.Typography.supportingBody)
                    .foregroundStyle(self.palette.textSecondary)
                    .multilineTextAlignment(.center)

                Button(action: self.retry) {
                    Label("Try Again", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(LiquidProminentButtonStyle(palette: self.palette, emphasized: true))
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
