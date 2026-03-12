//
//  SavedView.swift
//  RunicQuotes
//
//  Created by Claude on 2026-03-12.
//

import SwiftUI

/// Displays bookmarked/favorited quotes.
struct SavedView: View {
    @Environment(\.colorScheme) private var colorScheme

    private var palette: AppThemePalette {
        .adaptive(for: colorScheme)
    }

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            Spacer()

            Image(systemName: "bookmark")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(palette.textTertiary)

            VStack(spacing: DesignTokens.Spacing.xs) {
                Text("No Saved Quotes")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(palette.textPrimary)

                Text("Quotes you save will appear here.")
                    .font(.subheadline)
                    .foregroundStyle(palette.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
        .padding(.horizontal, DesignTokens.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(palette.background)
        .navigationTitle("Saved")
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SavedView()
    }
}
