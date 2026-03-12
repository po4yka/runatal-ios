//
//  ArchiveView.swift
//  RunicQuotes
//
//  Created by Claude on 2026-03-12.
//

import SwiftUI
import SwiftData

// MARK: - Archive Filter

/// Filter tabs for the archive view.
enum ArchiveFilter: String, Codable, CaseIterable, Identifiable, Sendable {
    case all
    case hidden
    case deleted

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .all: return "All"
        case .hidden: return "Hidden"
        case .deleted: return "Deleted"
        }
    }
}

// MARK: - ArchiveView

/// Displays archived (hidden and soft-deleted) quotes with filter tabs and restore/erase actions.
struct ArchiveView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    @Query private var allQuotes: [Quote]
    @State private var selectedFilter: ArchiveFilter = .all
    @State private var restoredToastVisible = false

    private var palette: AppThemePalette {
        .adaptive(for: colorScheme)
    }

    // MARK: - Filtered Quotes

    private var archivedQuotes: [Quote] {
        allQuotes.filter { $0.isHidden || $0.isDeleted }
    }

    private var filteredQuotes: [Quote] {
        switch selectedFilter {
        case .all:
            return archivedQuotes
        case .hidden:
            return allQuotes.filter { $0.isHidden && !$0.isDeleted }
        case .deleted:
            return allQuotes.filter { $0.isDeleted }
        }
    }

    private var countLabel: String {
        let count = filteredQuotes.count
        switch selectedFilter {
        case .all:
            return "\(count) archived item\(count == 1 ? "" : "s")"
        case .hidden:
            return "\(count) hidden quote\(count == 1 ? "" : "s")"
        case .deleted:
            return "\(count) deleted quote\(count == 1 ? "" : "s")"
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            palette.background
                .ignoresSafeArea()

            if archivedQuotes.isEmpty {
                emptyState
            } else {
                archiveContent
            }

            if restoredToastVisible {
                restoredToast
            }
        }
        .navigationTitle("Archive")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Empty State

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            Spacer()

            Text("\u{16A8}\u{16B1}\u{16B2}")
                .font(.system(size: 48))
                .foregroundStyle(palette.textTertiary)

            VStack(spacing: DesignTokens.Spacing.xs) {
                Text("Nothing archived")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(palette.textPrimary)

                Text("Hidden and deleted quotes will appear here.")
                    .font(.subheadline)
                    .foregroundStyle(palette.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
        .padding(.horizontal, DesignTokens.Spacing.xl)
    }

    // MARK: - Archive Content

    @ViewBuilder
    private var archiveContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                filterTabs
                countHeader
                quotesList

                if selectedFilter == .deleted || selectedFilter == .all {
                    footerNote
                }
            }
            .padding(.top, DesignTokens.Spacing.sm)
            .padding(.bottom, DesignTokens.Spacing.huge)
        }
    }

    // MARK: - Filter Tabs

    @ViewBuilder
    private var filterTabs: some View {
        HStack(spacing: 2) {
            ForEach(ArchiveFilter.allCases) { filter in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedFilter = filter
                    }
                } label: {
                    Text(filter.displayName)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(
                            selectedFilter == filter
                                ? palette.textPrimary
                                : palette.textSecondary
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignTokens.Spacing.xs)
                        .background {
                            if selectedFilter == filter {
                                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md)
                                    .fill(palette.surface)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(2)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                .fill(palette.surface.opacity(0.3))
        )
        .padding(.horizontal, DesignTokens.Spacing.md)
    }

    // MARK: - Count Header

    @ViewBuilder
    private var countHeader: some View {
        Text(countLabel)
            .font(.subheadline)
            .foregroundStyle(palette.textSecondary)
            .padding(.horizontal, DesignTokens.Spacing.lg)
    }

    // MARK: - Quotes List

    @ViewBuilder
    private var quotesList: some View {
        LazyVStack(spacing: DesignTokens.Spacing.sm) {
            ForEach(filteredQuotes, id: \.id) { quote in
                archiveQuoteCard(quote)
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.sm)
    }

    // MARK: - Quote Card

    @ViewBuilder
    private func archiveQuoteCard(_ quote: Quote) -> some View {
        GlassCard(
            intensity: .light,
            cornerRadius: DesignTokens.CornerRadius.xl,
            shadowRadius: 4
        ) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                // Top row: runic snippet + status tag
                HStack(alignment: .top) {
                    Text(quote.runicElder ?? "")
                        .font(.caption2)
                        .foregroundStyle(palette.runeText.opacity(0.6))
                        .lineLimit(1)

                    Spacer()

                    statusTag(for: quote)
                }

                // Quote text
                Text("\u{201C}\(quote.textLatin)\u{201D}")
                    .font(.body)
                    .foregroundStyle(palette.textPrimary)
                    .lineLimit(3)

                // Author
                Text(quote.author)
                    .font(.subheadline)
                    .foregroundStyle(palette.accent)

                // Actions
                HStack(spacing: DesignTokens.Spacing.md) {
                    Spacer()
                    actionButtons(for: quote)
                }
            }
        }
    }

    // MARK: - Status Tag

    @ViewBuilder
    private func statusTag(for quote: Quote) -> some View {
        let label = quote.isDeleted ? "Deleted" : "Hidden"
        let color = quote.isDeleted ? palette.error : palette.warning

        Text(label)
            .font(.caption2.weight(.medium))
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
    private func actionButtons(for quote: Quote) -> some View {
        if quote.isDeleted {
            Button {
                restoreQuote(quote)
            } label: {
                Text("Restore")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(palette.accent)
            }
            .buttonStyle(.plain)

            Button {
                eraseQuote(quote)
            } label: {
                Text("Erase")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(palette.error)
            }
            .buttonStyle(.plain)
        } else if quote.isHidden {
            Button {
                unhideQuote(quote)
            } label: {
                Text("Unhide")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(palette.accent)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Footer Note

    @ViewBuilder
    private var footerNote: some View {
        Text("Deleted quotes are removed after 30 days.")
            .font(.caption)
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

    // MARK: - Actions

    private func restoreQuote(_ quote: Quote) {
        quote.isHidden = false
        quote.isDeleted = false
        quote.deletedAt = nil
        showRestoredToast()
    }

    private func unhideQuote(_ quote: Quote) {
        quote.isHidden = false
        showRestoredToast()
    }

    private func eraseQuote(_ quote: Quote) {
        modelContext.delete(quote)
    }

    @State private var toastDismissTask: Task<Void, Never>?

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
        ArchiveView()
    }
    .modelContainer(for: [Quote.self, UserPreferences.self], inMemory: true)
}
