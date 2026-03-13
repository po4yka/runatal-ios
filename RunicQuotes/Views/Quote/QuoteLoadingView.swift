//
//  QuoteLoadingView.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import SwiftUI

struct QuoteLoadingView: View {
    let palette: AppThemePalette

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            ProgressView()
                .tint(self.palette.accent)
                .scaleEffect(1.5)
                .accessibilityLabel("Loading")
                .accessibilityIdentifier("quote_loading_indicator")

            Text("Loading quote...")
                .font(.caption)
                .foregroundStyle(self.palette.textTertiary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Loading quote")
        .accessibilityIdentifier("quote_loading_view")
    }
}
