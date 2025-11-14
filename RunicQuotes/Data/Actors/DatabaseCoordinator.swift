//
//  DatabaseCoordinator.swift
//  RunicQuotes
//
//  Created by Claude on 2025-11-15.
//

import Foundation
import SwiftData
import os

/// Thread-safe coordinator for database seeding operations
/// Prevents race conditions when both app and widget attempt to seed simultaneously
actor DatabaseCoordinator {
    private static let logger = Logger(subsystem: AppConstants.loggingSubsystem, category: "DatabaseCoordinator")

    private var isSeedingInProgress = false
    private var seedingTask: Task<Void, Error>?

    /// Seed the database if needed, ensuring only one seeding operation runs at a time
    /// - Parameter container: The ModelContainer to use for seeding
    func seedIfNeeded(using container: ModelContainer) async throws {
        // If seeding is already in progress, wait for it to complete
        if let existingTask = seedingTask {
            Self.logger.debug("Seeding already in progress, waiting for completion")
            try await existingTask.value
            return
        }

        // Check if already seeding
        guard !isSeedingInProgress else {
            Self.logger.debug("Seeding check bypassed - already in progress")
            return
        }

        // Mark as in progress
        isSeedingInProgress = true

        // Create seeding task
        seedingTask = Task {
            defer {
                isSeedingInProgress = false
                seedingTask = nil
            }

            do {
                let context = ModelContext(container)
                let repository = SwiftDataQuoteRepository(modelContext: context)
                try await repository.seedIfNeeded()
                Self.logger.info("Database seeding completed successfully")
            } catch {
                Self.logger.error("Database seeding failed: \(error.localizedDescription)")
                throw error
            }
        }

        // Wait for completion
        try await seedingTask?.value
    }
}

/// Shared instance of the database coordinator
@globalActor
actor DatabaseActor {
    static let shared = DatabaseCoordinator()
}
