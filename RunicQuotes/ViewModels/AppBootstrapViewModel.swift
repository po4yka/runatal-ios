//
//  AppBootstrapViewModel.swift
//  RunicQuotes
//
//  Created by Claude on 09.10.26.
//

import Combine
import Foundation

protocol AppDatabasePreparing: Sendable {
    func seedIfNeeded() async throws
    func purgeExpiredQuotes() async throws
    func backfillTranslations() async
}

extension DatabaseCoordinator: AppDatabasePreparing {}

enum AppBootstrapPhase: Equatable {
    case loading
    case ready
    case failed(String)
}

@MainActor
final class AppBootstrapViewModel: ObservableObject {
    @Published private(set) var phase: AppBootstrapPhase = .loading
    @Published private(set) var pendingURLs: [URL] = []
    private let database: any AppDatabasePreparing
    private var isPreparing = false
    private var maintenanceTask: Task<Void, Never>?

    init(database: any AppDatabasePreparing) {
        self.database = database
    }

    func prepare() async {
        guard !self.isPreparing, self.phase != .ready else { return }
        self.isPreparing = true
        self.phase = .loading
        defer { self.isPreparing = false }
        do {
            try await self.database.seedIfNeeded()
            try Task.checkCancellation()
            try await self.database.purgeExpiredQuotes()
            try Task.checkCancellation()
            self.phase = .ready
            let database = self.database
            self.maintenanceTask = Task(priority: .utility) {
                await database.backfillTranslations()
            }
        } catch is CancellationError {
            self.phase = .loading
        } catch {
            self.phase = .failed(error.localizedDescription)
        }
    }

    func enqueue(_ url: URL) {
        self.pendingURLs.append(url)
    }

    func consumePendingURLs() -> [URL] {
        guard self.phase == .ready else { return [] }
        let queued = self.pendingURLs
        self.pendingURLs.removeAll()
        return queued
    }
}
