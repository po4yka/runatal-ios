//
//  CollectionsView.swift
//  RunicQuotes
//
//  Created by Claude on 2026-03-12.
//

import SwiftUI

/// Browse quotes organized by collection.
struct CollectionsView: View {
    @Environment(\.colorScheme) private var colorScheme

    private var palette: AppThemePalette {
        .adaptive(for: colorScheme)
    }

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            Spacer()

            Image(systemName: "square.grid.2x2")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(palette.textTertiary)

            VStack(spacing: DesignTokens.Spacing.xs) {
                Text("No Collections Yet")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(palette.textPrimary)

                Text("Your quote collections will appear here.")
                    .font(.subheadline)
                    .foregroundStyle(palette.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
        .padding(.horizontal, DesignTokens.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(palette.background)
        .navigationTitle("Collections")
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        CollectionsView()
    }
}
