//
//  ArchiveView.swift
//  RunicQuotes
//
//  Created by Claude on 12.03.26.
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
        .themed(self.runicTheme, for: self.colorScheme)
    }

    // MARK: - Initialization

    init(viewModel: ArchiveViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        LiquidListScaffold(palette: self.palette) {
            Section {
                HeroHeader(
                    eyebrow: "Archive",
                    title: "Recovery Shelf",
                    subtitle: "Hidden and deleted passages rest here until you decide what returns.",
                    meta: [self.viewModel.countLabel],
                    palette: self.palette,
                )
                .listRowInsets(EdgeInsets(
                    top: DesignTokens.Spacing.lg,
                    leading: DesignTokens.Spacing.md,
                    bottom: DesignTokens.Spacing.md,
                    trailing: DesignTokens.Spacing.md,
                ))
            }

            if self.restoredToastVisible {
                Section {
                    FeedbackBanner(
                        palette: self.palette,
                        tone: .success,
                        title: "Restored",
                        message: "The passage returned to your library.",
                    )
                }
            }

            Section {
                if !self.viewModel.hasArchivedQuotes {
                    self.emptyState
                } else {
                    self.archiveContent
                }
            }
        }
        .navigationTitle("Archive")
        #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
        #endif
            .task {
                guard !self.didInitialize else { return }
                self.didInitialize = true
                self.viewModel.onAppear()
            }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        EditorialEmptyState(
            palette: self.palette,
            icon: "archivebox",
            eyebrow: "Archive",
            title: "Nothing is resting here",
            message: "Hidden and deleted passages will appear here when you need to reverse a choice.",
        )
    }

    // MARK: - Archive Content

    private var archiveContent: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            self.filterTabs
            self.quotesList

            if self.viewModel.state.selectedFilter == .deleted || self.viewModel.state.selectedFilter == .all {
                self.footerNote
            }
        }
    }

    // MARK: - Filter Tabs

    private var filterTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignTokens.Spacing.xs) {
                ForEach(ArchiveFilter.allCases) { filter in
                    FilterChip(
                        title: filter.displayName,
                        isSelected: self.viewModel.state.selectedFilter == filter,
                        palette: self.palette,
                    ) {
                        withAnimation(DesignTokens.Motion.emphasis) {
                            self.viewModel.updateFilter(filter)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Quotes List

    private var quotesList: some View {
        ForEach(self.viewModel.filteredQuotes) { quote in
            self.archiveQuoteRow(quote)
        }
    }

    // MARK: - Quote Row

    private func archiveQuoteRow(_ quote: QuoteRecord) -> some View {
        QuoteListRow(
            palette: self.palette,
            runicSnippet: quote.runicElder ?? "",
            quoteText: quote.textLatin,
            author: quote.author,
            metadata: [quote.collection.displayName],
            badge: {
                self.statusTag(for: quote)
            },
            footer: {
                self.actionButtons(for: quote)
            },
        )
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            if quote.isDeleted {
                Button(role: .destructive) {
                    self.viewModel.eraseQuote(quote.id)
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
        let color = quote.isDeleted ? self.palette.error : self.palette.warning

        Text(label)
            .font(DesignTokens.Typography.listMeta.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, DesignTokens.Spacing.xs)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xs)
                    .fill(color.opacity(0.15)),
            )
    }

    // MARK: - Action Buttons

    @ViewBuilder
    private func actionButtons(for quote: QuoteRecord) -> some View {
        if quote.isDeleted {
            Button {
                self.viewModel.restoreQuote(quote.id)
                self.showRestoredToast()
            } label: {
                Label("Restore", systemImage: "arrow.uturn.backward")
                    .font(DesignTokens.Typography.controlLabel)
                    .foregroundStyle(self.palette.accent)
            }
            .buttonStyle(.plain)
        } else if quote.isHidden {
            Button {
                self.viewModel.unhideQuote(quote.id)
                self.showRestoredToast()
            } label: {
                Label("Unhide", systemImage: "eye")
                    .font(DesignTokens.Typography.controlLabel)
                    .foregroundStyle(self.palette.accent)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Footer Note

    private var footerNote: some View {
        Text("Deleted quotes are removed after 30 days.")
            .font(DesignTokens.Typography.listMeta)
            .foregroundStyle(self.palette.textTertiary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, DesignTokens.Spacing.xs)
    }

    // MARK: - Restored Toast

    private var restoredToast: some View {
        VStack {
            Spacer()

            HStack(spacing: DesignTokens.Spacing.xs) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(self.palette.success)
                Text("Quote restored to your library")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(self.palette.textPrimary)
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.vertical, DesignTokens.Spacing.sm)
            .background(
                Capsule()
                    .fill(self.palette.surface)
                    .shadow(color: .black.opacity(0.2), radius: 8, y: 4),
            )
            .padding(.bottom, DesignTokens.Spacing.huge)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.spring(response: 0.4), value: self.restoredToastVisible)
    }

    // MARK: - Toast Helper

    private func showRestoredToast() {
        self.toastDismissTask?.cancel()
        withAnimation {
            self.restoredToastVisible = true
        }
        self.toastDismissTask = Task {
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            withAnimation {
                self.restoredToastVisible = false
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
