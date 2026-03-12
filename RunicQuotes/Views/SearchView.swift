//
//  SearchView.swift
//  RunicQuotes
//
//  Created by Claude on 2026-03-12.
//

import SwiftUI
import SwiftData

/// Search quotes by text, author, or collection with chip filters and result cards.
struct SearchView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Query(filter: #Predicate<Quote> { !$0.isDeleted && !$0.isHidden })
    private var quotes: [Quote]
    @State private var searchText = ""
    @State private var selectedCollection: QuoteCollection?

    private var palette: AppThemePalette {
        .adaptive(for: colorScheme)
    }

    // MARK: - Filtered Results

    private var filteredQuotes: [Quote] {
        var results = quotes

        if let collection = selectedCollection, collection != .all {
            results = results.filter { $0.collection == collection }
        }

        guard !searchText.isEmpty else { return [] }

        let query = searchText.lowercased()
        return results.filter { quote in
            quote.textLatin.lowercased().contains(query)
            || quote.author.lowercased().contains(query)
        }
    }

    private var isSearchActive: Bool {
        !searchText.isEmpty
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                if isSearchActive {
                    resultsContent
                } else {
                    suggestionsContent
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.top, DesignTokens.Spacing.sm)
            .padding(.bottom, DesignTokens.Spacing.huge)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(palette.background)
        .navigationTitle("Search")
        .searchable(text: $searchText, prompt: "Quotes, authors, themes...")
    }

    // MARK: - Suggestions Content

    @ViewBuilder
    private var suggestionsContent: some View {
        // Suggestions section
        sectionHeader("Suggestions")

        FlowLayout(spacing: DesignTokens.Spacing.xs) {
            ForEach(suggestionKeywords, id: \.self) { keyword in
                chipButton(keyword) {
                    searchText = keyword
                }
            }
        }
    }

    // MARK: - Results Content

    @ViewBuilder
    private var resultsContent: some View {
        // Results count + clear
        HStack {
            Text("\(filteredQuotes.count) results")
                .font(.subheadline)
                .foregroundStyle(palette.accent)

            Spacer()

            Button("Clear") {
                searchText = ""
                selectedCollection = nil
            }
            .font(.subheadline)
            .foregroundStyle(palette.textPrimary)
        }

        // Collection filter chips
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignTokens.Spacing.xs) {
                ForEach(QuoteCollection.allCases) { collection in
                    chipButton(
                        collection.displayName,
                        isSelected: selectedCollection == collection
                    ) {
                        if selectedCollection == collection {
                            selectedCollection = nil
                        } else {
                            selectedCollection = collection
                        }
                    }
                }
            }
        }

        // Result cards
        LazyVStack(spacing: DesignTokens.Spacing.sm) {
            ForEach(filteredQuotes, id: \.id) { quote in
                quoteResultCard(quote)
            }
        }
    }

    // MARK: - Quote Result Card

    @ViewBuilder
    private func quoteResultCard(_ quote: Quote) -> some View {
        QuoteCardView(
            runicSnippet: quote.runicElder ?? "",
            quoteText: quote.textLatin,
            author: quote.author,
            badge: {
                Text(quote.collection.displayName)
                    .font(.caption2)
                    .foregroundStyle(palette.accent)
            },
            actions: {
                HStack(spacing: DesignTokens.Spacing.sm) {
                    Image(systemName: "bookmark")
                        .font(.caption)
                        .foregroundStyle(palette.textTertiary)

                    Image(systemName: "doc.on.doc")
                        .font(.caption)
                        .foregroundStyle(palette.textTertiary)
                }
            }
        )
    }

    // MARK: - Chip Button

    @ViewBuilder
    private func chipButton(
        _ title: String,
        isSelected: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(isSelected ? palette.background : palette.textPrimary)
                .padding(.horizontal, DesignTokens.Spacing.sm)
                .padding(.vertical, DesignTokens.Spacing.xs)
                .background {
                    if isSelected {
                        Capsule()
                            .fill(palette.accent)
                    } else {
                        Capsule()
                            .strokeBorder(palette.separator, lineWidth: 1)
                    }
                }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Section Header

    @ViewBuilder
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.subheadline)
            .foregroundStyle(palette.accent)
            .padding(.top, DesignTokens.Spacing.xs)
    }

    // MARK: - Suggestion Keywords

    private var suggestionKeywords: [String] {
        ["Marcus Aurelius", "Tolkien", "courage", "strength", "wisdom", "hope"]
    }
}

// MARK: - Flow Layout

/// Simple flow layout that wraps chips to new lines.
private struct FlowLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(in: proposal.width ?? 0, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(in: bounds.width, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: ProposedViewSize(subviews[index].sizeThatFits(.unspecified))
            )
        }
    }

    private func layout(in width: CGFloat, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > width, currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            maxWidth = max(maxWidth, currentX)
        }

        return (
            size: CGSize(width: maxWidth, height: currentY + lineHeight),
            positions: positions
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SearchView()
    }
    .modelContainer(for: [Quote.self, UserPreferences.self], inMemory: true)
}
