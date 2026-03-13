//
//  ArchiveViewModel.swift
//  RunicQuotes
//
//  Created by Claude on 2026-03-12.
//

import Foundation

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

// MARK: - Archived Quote Item

/// ViewModel for the archive screen displaying hidden and soft-deleted quotes.
@MainActor
final class ArchiveViewModel: ObservableObject {
    // MARK: - State

    struct State: Sendable {
        var archivedQuotes: [QuoteRecord] = []
        var selectedFilter: ArchiveFilter = .all
        var isLoading: Bool = false
        var errorMessage: String?
    }

    @Published private(set) var state = State()

    // MARK: - Dependencies

    private let quoteProvider: QuoteProvider

    // MARK: - Computed Properties

    /// Quotes matching the currently selected filter tab.
    var filteredQuotes: [QuoteRecord] {
        switch state.selectedFilter {
        case .all:
            return state.archivedQuotes
        case .hidden:
            return state.archivedQuotes.filter { $0.isHidden && !$0.isDeleted }
        case .deleted:
            return state.archivedQuotes.filter { $0.isDeleted }
        }
    }

    /// Human-readable count label for the current filter.
    var countLabel: String {
        let count = filteredQuotes.count
        switch state.selectedFilter {
        case .all:
            return "\(count) archived item\(count == 1 ? "" : "s")"
        case .hidden:
            return "\(count) hidden quote\(count == 1 ? "" : "s")"
        case .deleted:
            return "\(count) deleted quote\(count == 1 ? "" : "s")"
        }
    }

    /// Whether there are any archived quotes at all (regardless of filter).
    var hasArchivedQuotes: Bool {
        !state.archivedQuotes.isEmpty
    }

    // MARK: - Initialization

    init(quoteProvider: QuoteProvider) {
        self.quoteProvider = quoteProvider
    }

    // MARK: - Public API

    /// Load archived quotes when the view appears.
    func onAppear() {
        Task {
            await loadArchivedQuotes()
        }
    }

    /// Switch the active filter tab.
    func updateFilter(_ filter: ArchiveFilter) {
        state.selectedFilter = filter
    }

    /// Restore a soft-deleted quote back to the main library.
    func restoreQuote(_ id: UUID) {
        Task {
            do {
                _ = try await quoteProvider.restoreQuote(id: id)
                await loadArchivedQuotes()
            } catch {
                state.errorMessage = "Failed to restore quote: \(error.localizedDescription)"
            }
        }
    }

    /// Unhide a hidden quote so it reappears in the main feed.
    func unhideQuote(_ id: UUID) {
        restoreQuote(id)
    }

    /// Permanently erase a quote from SwiftData.
    func eraseQuote(_ id: UUID) {
        Task {
            do {
                try await quoteProvider.eraseQuote(id: id)
                await loadArchivedQuotes()
            } catch {
                state.errorMessage = "Failed to erase quote: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Private Methods

    private func loadArchivedQuotes() async {
        state.isLoading = true
        state.errorMessage = nil

        do {
            state.archivedQuotes = try await quoteProvider.archivedQuotes()
            state.isLoading = false
        } catch {
            state.errorMessage = "Failed to load archived quotes: \(error.localizedDescription)"
            state.isLoading = false
        }
    }
}

// MARK: - Preview Helper

extension ArchiveViewModel {
    /// Create a view model for SwiftUI previews.
    static func preview() -> ArchiveViewModel {
        let container = ModelContainerHelper.createPlaceholderContainer()
        let quoteRepository = SwiftDataQuoteRepository(modelContext: container.mainContext)
        return ArchiveViewModel(quoteProvider: QuoteProvider(repository: quoteRepository))
    }
}
