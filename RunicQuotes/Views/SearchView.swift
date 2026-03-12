//
//  SearchView.swift
//  RunicQuotes
//
//  Created by Claude on 2026-03-12.
//

import SwiftUI

/// Search quotes by text, author, or collection.
struct SearchView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var searchText = ""

    private var palette: AppThemePalette {
        .adaptive(for: colorScheme)
    }

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            Spacer()

            Image(systemName: "magnifyingglass")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(palette.textTertiary)

            VStack(spacing: DesignTokens.Spacing.xs) {
                Text("Search Quotes")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(palette.textPrimary)

                Text("Find quotes by text, author, or collection.")
                    .font(.subheadline)
                    .foregroundStyle(palette.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
        .padding(.horizontal, DesignTokens.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(palette.background)
        .navigationTitle("Search")
        .searchable(text: $searchText, prompt: "Search quotes...")
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SearchView()
    }
}
