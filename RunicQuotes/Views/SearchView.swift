//
//  SearchView.swift
//  RunicQuotes
//
//  Created by Claude on 2026-03-12.
//

import SwiftUI

/// Search quotes by text, author, or collection with chip filters and result cards.
struct SearchView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.runicTheme) private var runicTheme
    @EnvironmentObject private var searchCoordinator: AppSearchCoordinator
    @StateObject private var viewModel: SearchViewModel
    @State private var didInitialize = false

    private var palette: AppThemePalette {
        .themed(runicTheme, for: colorScheme)
    }

    init(viewModel: SearchViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        ScreenScaffold(palette: palette) {
            if !viewModel.state.isSearchActive {
                HeroHeader(
                    eyebrow: "Search",
                    title: "Find a Line",
                    subtitle: "Search by author, theme, or a fragment you remember.",
                    meta: searchMeta,
                    palette: palette
                )
            }

            if let error = viewModel.state.errorMessage {
                FeedbackBanner(
                    palette: palette,
                    tone: .error,
                    title: "Search unavailable",
                    message: error
                )
            }

            if viewModel.state.isLoading {
                InsetCard(palette: palette) {
                    HStack(spacing: DesignTokens.Spacing.sm) {
                        ProgressView()
                            .tint(palette.accent)

                        Text("Preparing the archive...")
                            .font(DesignTokens.Typography.callout)
                            .foregroundStyle(palette.textSecondary)
                    }
                }
            } else if viewModel.state.isSearchActive {
                resultsContent
            } else {
                suggestionsContent
            }
        }
        .navigationTitle("Search")
        .task {
            guard !didInitialize else { return }
            didInitialize = true
            viewModel.onAppear()
            viewModel.updateSearchText(searchCoordinator.query)
        }
        .onAppear {
            searchCoordinator.isPresented = true
        }
        .onDisappear {
            searchCoordinator.isPresented = false
        }
        .onChange(of: searchCoordinator.query) { _, newValue in
            viewModel.updateSearchText(newValue)
        }
    }

    // MARK: - Suggestions Content

    @ViewBuilder
    private var suggestionsContent: some View {
        EditorialCard(
            palette: palette,
            tone: .secondary,
            cornerRadius: DesignTokens.CornerRadius.xl,
            shadowRadius: DesignTokens.Elevation.low
        ) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                SectionLabel(title: "Suggestions", palette: palette)

                Text("Start with an author, a mood, or a single remembered word.")
                    .font(DesignTokens.Typography.callout)
                    .foregroundStyle(palette.textSecondary)

                FlowLayout(spacing: DesignTokens.Spacing.xs) {
                    ForEach(viewModel.suggestionKeywords, id: \.self) { keyword in
                        FilterChip(title: keyword, isSelected: false, palette: palette) {
                            viewModel.updateSearchText(keyword)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Results Content

    @ViewBuilder
    private var resultsContent: some View {
        InsetCard(
            palette: palette,
            cornerRadius: DesignTokens.CornerRadius.xl,
            contentPadding: DesignTokens.Spacing.md
        ) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                        SectionLabel(title: "Active Search", palette: palette)
                        Text("\(viewModel.state.filteredQuotes.count) results")
                            .font(DesignTokens.Typography.sectionTitle)
                            .foregroundStyle(palette.textPrimary)
                    }

                    Spacer()

                    Button("Clear") {
                        viewModel.clearSearch()
                        searchCoordinator.clear()
                    }
                    .font(DesignTokens.Typography.label)
                    .foregroundStyle(palette.accent)
                }

                ScrollView(.horizontal) {
                    HStack(spacing: DesignTokens.Spacing.xs) {
                        ForEach(QuoteCollection.allCases) { collection in
                            FilterChip(
                                title: collection.displayName,
                                isSelected: viewModel.state.selectedCollection == collection,
                                palette: palette
                            ) {
                                viewModel.updateSelectedCollection(collection)
                            }
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
        }

        if viewModel.state.filteredQuotes.isEmpty {
            EditorialEmptyState(
                palette: palette,
                icon: "magnifyingglass",
                eyebrow: "No matches",
                title: "Nothing surfaced",
                message: "Try a different author, broader wording, or switch the collection filter."
            )
        } else {
            LazyVStack(spacing: DesignTokens.Spacing.sm) {
                ForEach(viewModel.state.filteredQuotes, id: \.id) { quote in
                    quoteResultCard(quote)
                }
            }
        }
    }

    // MARK: - Quote Result Card

    @ViewBuilder
    private func quoteResultCard(_ quote: QuoteRecord) -> some View {
        QuoteCardView(
            runicSnippet: quote.runicElder ?? "",
            quoteText: quote.textLatin,
            author: quote.author,
            badge: {
                Text(quote.collection.displayName)
                    .font(DesignTokens.Typography.metadata)
                    .foregroundStyle(palette.accent)
                    .padding(.horizontal, DesignTokens.Spacing.sm)
                    .padding(.vertical, DesignTokens.Spacing.xs)
                    .background {
                        Capsule()
                            .fill(palette.bannerBackground)
                    }
            },
            actions: {
                EmptyView()
            }
        )
    }

    private var searchMeta: [String] {
        var items = ["Authors", "Collections", "Fragments"]
        if let collection = viewModel.state.selectedCollection {
            items.append(collection.displayName)
        }
        return items
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
        SearchView(viewModel: SearchViewModel.preview())
    }
    .modelContainer(for: [Quote.self, UserPreferences.self], inMemory: true)
}
