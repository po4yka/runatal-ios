//
//  SearchView.swift
//  RunicQuotes
//
//  Created by Claude on 12.03.26.
//

import SwiftUI
import TipKit

/// Search quotes by text, author, or collection with chip filters and result cards.
struct SearchView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.runicTheme) private var runicTheme
    @EnvironmentObject private var searchCoordinator: AppSearchCoordinator
    @EnvironmentObject private var featureDiscoveryController: FeatureDiscoveryController
    @StateObject private var viewModel: SearchViewModel
    @State private var didInitialize = false

    private var palette: AppThemePalette {
        .themed(self.runicTheme, for: self.colorScheme)
    }

    init(viewModel: SearchViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        ScreenScaffold(palette: self.palette) {
            if !self.viewModel.state.isSearchActive {
                HeroHeader(
                    eyebrow: "Search",
                    title: "Find a Line",
                    subtitle: "Search by author, theme, or a fragment you remember.",
                    meta: self.searchMeta,
                    palette: self.palette,
                )
            }

            if let error = viewModel.state.errorMessage {
                FeedbackBanner(
                    palette: self.palette,
                    tone: .error,
                    title: "Search unavailable",
                    message: error,
                )
            }

            if self.viewModel.state.isLoading {
                InsetCard(palette: self.palette) {
                    HStack(spacing: DesignTokens.Spacing.sm) {
                        ProgressView()
                            .tint(self.palette.accent)

                        Text("Preparing the archive...")
                            .font(DesignTokens.Typography.callout)
                            .foregroundStyle(self.palette.textSecondary)
                    }
                }
            } else if self.viewModel.state.isSearchActive {
                self.resultsContent
            } else {
                self.suggestionsContent
            }
        }
        .navigationTitle("Search")
        .task {
            guard !self.didInitialize else { return }
            self.didInitialize = true
            self.viewModel.onAppear()
            self.viewModel.updateSearchText(self.searchCoordinator.query)
        }
        .onAppear {
            self.searchCoordinator.isPresented = true
        }
        .onDisappear {
            self.searchCoordinator.isPresented = false
        }
        .onChange(of: self.searchCoordinator.query) { _, newValue in
            self.viewModel.updateSearchText(newValue)
        }
    }

    // MARK: - Suggestions Content

    private var suggestionsContent: some View {
        EditorialCard(
            palette: self.palette,
            tone: .secondary,
            cornerRadius: DesignTokens.CornerRadius.xl,
            shadowRadius: DesignTokens.Elevation.low,
        ) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                SectionLabel(title: "Suggestions", palette: self.palette)

                Text("Start with an author, a mood, or a single remembered word.")
                    .font(DesignTokens.Typography.callout)
                    .foregroundStyle(self.palette.textSecondary)

                FlowLayout(spacing: DesignTokens.Spacing.xs) {
                    ForEach(self.viewModel.suggestionKeywords, id: \.self) { keyword in
                        FilterChip(title: keyword, isSelected: false, palette: self.palette) {
                            self.searchCoordinator.query = keyword
                            self.viewModel.updateSearchText(keyword)
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
            palette: self.palette,
            cornerRadius: DesignTokens.CornerRadius.xl,
            contentPadding: DesignTokens.Spacing.md,
        ) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                        SectionLabel(title: "Active Search", palette: self.palette)
                        Text("\(self.viewModel.state.filteredQuotes.count) results")
                            .font(DesignTokens.Typography.sectionTitle)
                            .foregroundStyle(self.palette.textPrimary)
                    }

                    Spacer()

                    Button("Clear") {
                        self.viewModel.clearSearch()
                        self.searchCoordinator.clear()
                    }
                    .font(DesignTokens.Typography.label)
                    .foregroundStyle(self.palette.accent)
                }

                if !self.viewModel.state.filteredQuotes.isEmpty {
                    RunicInlineTip(
                        tip: SearchCollectionFilterTip(),
                        palette: self.palette,
                        refreshID: self.featureDiscoveryController.refreshID,
                        accessibilityIdentifier: "tip_search_collection_filter",
                    )
                }

                ScrollView(.horizontal) {
                    HStack(spacing: DesignTokens.Spacing.xs) {
                        ForEach(QuoteCollection.allCases) { collection in
                            FilterChip(
                                title: collection.displayName,
                                isSelected: self.viewModel.state.selectedCollection == collection,
                                palette: self.palette,
                            ) {
                                self.viewModel.updateSelectedCollection(collection)
                                FeatureDiscoveryEvents.searchSelectedCollectionFilter.sendDonation()
                                SearchCollectionFilterTip().invalidate(reason: .actionPerformed)
                            }
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
        }

        if self.viewModel.state.filteredQuotes.isEmpty {
            EditorialEmptyState(
                palette: self.palette,
                icon: "magnifyingglass",
                eyebrow: "No matches",
                title: "Nothing surfaced",
                message: "Try a different author, broader wording, or switch the collection filter.",
            )
        } else {
            LazyVStack(spacing: DesignTokens.Spacing.sm) {
                ForEach(self.viewModel.state.filteredQuotes, id: \.id) { quote in
                    self.quoteResultCard(quote)
                }
            }
        }
    }

    // MARK: - Quote Result Card

    private func quoteResultCard(_ quote: QuoteRecord) -> some View {
        QuoteCardView(
            runicSnippet: quote.runicElder ?? "",
            quoteText: quote.textLatin,
            author: quote.author,
            badge: {
                Text(quote.collection.displayName)
                    .font(DesignTokens.Typography.metadata)
                    .foregroundStyle(self.palette.accent)
                    .padding(.horizontal, DesignTokens.Spacing.sm)
                    .padding(.vertical, DesignTokens.Spacing.xs)
                    .background {
                        Capsule()
                            .fill(self.palette.bannerBackground)
                    }
            },
            actions: {
                EmptyView()
            },
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
        let result = self.layout(in: proposal.width ?? 0, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = self.layout(in: bounds.width, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: ProposedViewSize(subviews[index].sizeThatFits(.unspecified)),
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
                currentY += lineHeight + self.spacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + self.spacing
            maxWidth = max(maxWidth, currentX)
        }

        return (
            size: CGSize(width: maxWidth, height: currentY + lineHeight),
            positions: positions,
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SearchView(viewModel: SearchViewModel.preview())
    }
    .modelContainer(for: [Quote.self, UserPreferences.self], inMemory: true)
    .environmentObject(FeatureDiscoveryController.preview())
}
