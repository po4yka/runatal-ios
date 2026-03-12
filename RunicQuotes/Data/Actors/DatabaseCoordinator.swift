//
//  DatabaseCoordinator.swift
//  RunicQuotes
//
//  Created by Claude on 2025-11-15.
//

import Foundation
import SwiftData
import os

/// Thread-safe coordinator for database seeding and maintenance operations.
/// Prevents race conditions when both app and widget attempt to seed simultaneously.
actor DatabaseCoordinator {
    private static let logger = Logger(subsystem: AppConstants.loggingSubsystem, category: "DatabaseCoordinator")

    private var seedingTask: Task<Void, Error>?

    /// Seed the database if needed, ensuring only one seeding operation runs at a time.
    /// - Parameter container: The ModelContainer to use for seeding
    func seedIfNeeded(using container: ModelContainer) async throws {
        // If seeding is already in progress, wait for it to complete
        if let existingTask = seedingTask {
            Self.logger.debug("Seeding already in progress, waiting for completion")
            try await existingTask.value
            return
        }

        let task = Task {
            do {
                let context = ModelContext(container)
                let repository = SwiftDataQuoteRepository(modelContext: context)
                try repository.seedIfNeeded()
                Self.logger.info("Database seeding completed successfully")
            } catch {
                Self.logger.error("Database seeding failed: \(error.localizedDescription)")
                throw error
            }
        }

        seedingTask = task
        defer { seedingTask = nil }

        // Wait for completion
        try await task.value
    }

    /// Purge quotes that were soft-deleted more than 30 days ago.
    /// - Parameter container: The ModelContainer to use
    func purgeExpiredQuotes(using container: ModelContainer) async {
        let context = ModelContext(container)
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()

        do {
            let descriptor = FetchDescriptor<Quote>(
                predicate: #Predicate { $0.isDeleted && $0.deletedAt != nil }
            )
            let deletedQuotes = try context.fetch(descriptor)
            var purgedCount = 0

            for quote in deletedQuotes {
                if let deletedAt = quote.deletedAt, deletedAt < cutoffDate {
                    context.delete(quote)
                    purgedCount += 1
                }
            }

            if purgedCount > 0 {
                try context.save()
                Self.logger.info("Purged \(purgedCount) expired quote(s)")
            }
        } catch {
            Self.logger.error("Failed to purge expired quotes: \(error.localizedDescription)")
        }
    }
}

/// Shared instance of the database coordinator
@globalActor
actor DatabaseActor {
    static let shared = DatabaseCoordinator()
}
