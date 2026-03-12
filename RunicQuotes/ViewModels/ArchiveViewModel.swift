//
//  ArchiveViewModel.swift
//  RunicQuotes
//
//  Created by Claude on 2026-03-12.
//

import Foundation
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

// MARK: - Archived Quote Item

/// Lightweight, Sendable snapshot of an archived quote for the view layer.
struct ArchivedQuoteItem: Identifiable, Sendable {
    let id: UUID
    let textLatin: String
    let author: String
    let runicElder: String?
    let isHidden: Bool
    let isDeleted: Bool
}

// MARK: - ArchiveViewModel

/// ViewModel for the archive screen displaying hidden and soft-deleted quotes.
@MainActor
final class ArchiveViewModel: ObservableObject {
    // MARK: - State

    struct State: Sendable {
        var archivedQuotes: [ArchivedQuoteItem] = []
        var selectedFilter: ArchiveFilter = .all
        var isLoading: Bool = false
        var errorMessage: String?
    }

    @Published private(set) var state = State()

    // MARK: - Dependencies

    private var modelContext: ModelContext
    private var isConfiguredWithEnvironmentContext = false

    // MARK: - Computed Properties

    /// Quotes matching the currently selected filter tab.
    var filteredQuotes: [ArchivedQuoteItem] {
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

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Public API

    /// Rebind dependencies to the environment-provided context once the view is mounted.
    func configureIfNeeded(modelContext: ModelContext) {
        guard !isConfiguredWithEnvironmentContext else { return }
        self.modelContext = modelContext
        isConfiguredWithEnvironmentContext = true
    }

    /// Load archived quotes when the view appears.
    func onAppear() {
        loadArchivedQuotes()
    }

    /// Switch the active filter tab.
    func updateFilter(_ filter: ArchiveFilter) {
        state.selectedFilter = filter
    }

    /// Restore a soft-deleted quote back to the main library.
    func restoreQuote(_ id: UUID) {
        guard let quote = fetchQuote(by: id) else { return }
        quote.isHidden = false
        quote.isDeleted = false
        quote.deletedAt = nil
        save()
        loadArchivedQuotes()
    }

    /// Unhide a hidden quote so it reappears in the main feed.
    func unhideQuote(_ id: UUID) {
        guard let quote = fetchQuote(by: id) else { return }
        quote.isHidden = false
        save()
        loadArchivedQuotes()
    }

    /// Permanently erase a quote from SwiftData.
    func eraseQuote(_ id: UUID) {
        guard let quote = fetchQuote(by: id) else { return }
        modelContext.delete(quote)
        save()
        loadArchivedQuotes()
    }

    // MARK: - Private Methods

    private func loadArchivedQuotes() {
        state.isLoading = true
        state.errorMessage = nil

        do {
            let descriptor = FetchDescriptor<Quote>(
                predicate: #Predicate<Quote> { $0.isHidden || $0.isDeleted }
            )
            let quotes = try modelContext.fetch(descriptor)
            state.archivedQuotes = quotes.map { quote in
                ArchivedQuoteItem(
                    id: quote.id,
                    textLatin: quote.textLatin,
                    author: quote.author,
                    runicElder: quote.runicElder,
                    isHidden: quote.isHidden,
                    isDeleted: quote.isDeleted
                )
            }
            state.isLoading = false
        } catch {
            state.errorMessage = "Failed to load archived quotes: \(error.localizedDescription)"
            state.isLoading = false
        }
    }

    private func fetchQuote(by id: UUID) -> Quote? {
        let descriptor = FetchDescriptor<Quote>(
            predicate: #Predicate<Quote> { $0.id == id }
        )
        return try? modelContext.fetch(descriptor).first
    }

    private func save() {
        do {
            try modelContext.save()
        } catch {
            state.errorMessage = "Failed to save changes: \(error.localizedDescription)"
        }
    }
}

// MARK: - Preview Helper

extension ArchiveViewModel {
    /// Create a view model for SwiftUI previews.
    static func preview() -> ArchiveViewModel {
        let container = ModelContainerHelper.createPlaceholderContainer()
        return ArchiveViewModel(modelContext: container.mainContext)
    }
}
