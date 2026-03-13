//
//  ArchiveView.swift
//  RunicQuotes
//
//  Created by Claude on 2026-03-12.
//

import SwiftUI

// MARK: - ArchiveView

/// Displays archived (hidden and soft-deleted) quotes with filter tabs and restore/erase actions.
struct ArchiveView: View {
    @StateObject private var viewModel: ArchiveViewModel
    @State private var didInitialize = false
    @State private var restoredToastVisible = false
    @State private var toastDismissTask: Task<Void, Never>?
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.runicTheme) private var runicTheme

    private var palette: AppThemePalette {
        .themed(runicTheme, for: colorScheme)
    }

    // MARK: - Initialization

    init(viewModel: ArchiveViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        LiquidListScaffold(palette: palette) {
            Section {
                HeroHeader(
                    eyebrow: "Archive",
                    title: "Recovery Shelf",
                    subtitle: "Hidden and deleted passages rest here until you decide what returns.",
                    meta: [viewModel.countLabel],
                    palette: palette
                )
                .listRowInsets(EdgeInsets(
                    top: DesignTokens.Spacing.lg,
                    leading: DesignTokens.Spacing.md,
                    bottom: DesignTokens.Spacing.md,
                    trailing: DesignTokens.Spacing.md
                ))
            }

            if restoredToastVisible {
                Section {
                    FeedbackBanner(
                        palette: palette,
                        tone: .success,
                        title: "Restored",
                        message: "The passage returned to your library."
                    )
                }
            }

            Section {
                if !viewModel.hasArchivedQuotes {
                    emptyState
                } else {
                    archiveContent
                }
            }
        }
        .navigationTitle("Archive")
#if os(iOS)
        .navigationBarTitleDisplayMode(.large)
#endif
        .task {
            guard !didInitialize else { return }
            didInitialize = true
            viewModel.onAppear()
        }
    }

    // MARK: - Empty State

    @ViewBuilder
    private var emptyState: some View {
        EditorialEmptyState(
            palette: palette,
            icon: "archivebox",
            eyebrow: "Archive",
            title: "Nothing is resting here",
            message: "Hidden and deleted passages will appear here when you need to reverse a choice."
        )
    }

    // MARK: - Archive Content

    @ViewBuilder
    private var archiveContent: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            filterTabs
            quotesList

            if viewModel.state.selectedFilter == .deleted || viewModel.state.selectedFilter == .all {
                footerNote
            }
        }
    }

    // MARK: - Filter Tabs

    @ViewBuilder
    private var filterTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignTokens.Spacing.xs) {
                ForEach(ArchiveFilter.allCases) { filter in
                    FilterChip(
                        title: filter.displayName,
                        isSelected: viewModel.state.selectedFilter == filter,
                        palette: palette
                    ) {
                        withAnimation(DesignTokens.Motion.emphasis) {
                            viewModel.updateFilter(filter)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Quotes List

    @ViewBuilder
    private var quotesList: some View {
        ForEach(viewModel.filteredQuotes) { quote in
            archiveQuoteRow(quote)
        }
    }

    // MARK: - Quote Row

    @ViewBuilder
    private func archiveQuoteRow(_ quote: QuoteRecord) -> some View {
        QuoteListRow(
            palette: palette,
            runicSnippet: quote.runicElder ?? "",
            quoteText: quote.textLatin,
            author: quote.author,
            metadata: [quote.collection.displayName],
            badge: {
                statusTag(for: quote)
            },
            footer: {
                actionButtons(for: quote)
            }
        )
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            if quote.isDeleted {
                Button(role: .destructive) {
                    viewModel.eraseQuote(quote.id)
                } label: {
                    Label("Erase", systemImage: "trash")
                }
            }
        }
    }

    // MARK: - Status Tag

    @ViewBuilder
    private func statusTag(for quote: QuoteRecord) -> some View {
        let label = quote.isDeleted ? "Deleted" : "Hidden"
        let color = quote.isDeleted ? palette.error : palette.warning

        Text(label)
            .font(DesignTokens.Typography.listMeta.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, DesignTokens.Spacing.xs)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xs)
                    .fill(color.opacity(0.15))
            )
    }

    // MARK: - Action Buttons

    @ViewBuilder
    private func actionButtons(for quote: QuoteRecord) -> some View {
        if quote.isDeleted {
            Button {
                viewModel.restoreQuote(quote.id)
                showRestoredToast()
            } label: {
                Label("Restore", systemImage: "arrow.uturn.backward")
                    .font(DesignTokens.Typography.controlLabel)
                    .foregroundStyle(palette.accent)
            }
            .buttonStyle(.plain)
        } else if quote.isHidden {
            Button {
                viewModel.unhideQuote(quote.id)
                showRestoredToast()
            } label: {
                Label("Unhide", systemImage: "eye")
                    .font(DesignTokens.Typography.controlLabel)
                    .foregroundStyle(palette.accent)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Footer Note

    @ViewBuilder
    private var footerNote: some View {
        Text("Deleted quotes are removed after 30 days.")
            .font(DesignTokens.Typography.listMeta)
            .foregroundStyle(palette.textTertiary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, DesignTokens.Spacing.xs)
    }

    // MARK: - Restored Toast

    @ViewBuilder
    private var restoredToast: some View {
        VStack {
            Spacer()

            HStack(spacing: DesignTokens.Spacing.xs) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(palette.success)
                Text("Quote restored to your library")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(palette.textPrimary)
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.vertical, DesignTokens.Spacing.sm)
            .background(
                Capsule()
                    .fill(palette.surface)
                    .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
            )
            .padding(.bottom, DesignTokens.Spacing.huge)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.spring(response: 0.4), value: restoredToastVisible)
    }

    // MARK: - Toast Helper

    private func showRestoredToast() {
        toastDismissTask?.cancel()
        withAnimation {
            restoredToastVisible = true
        }
        toastDismissTask = Task {
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            withAnimation {
                restoredToastVisible = false
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ArchiveView(viewModel: ArchiveViewModel.preview())
    }
    .modelContainer(for: [Quote.self, UserPreferences.self], inMemory: true)
}
