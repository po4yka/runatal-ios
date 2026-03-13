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
actor DatabaseCoordinator {
    private static let logger = Logger(subsystem: AppConstants.loggingSubsystem, category: "DatabaseCoordinator")

    private let modelContainer: ModelContainer
    private let translationService: HistoricalTranslationService
    private var seedingTask: Task<Void, Error>?
    private var translationBackfillTask: Task<Void, Error>?

    init(
        modelContainer: ModelContainer,
        translationService: HistoricalTranslationService = HistoricalTranslationService()
    ) {
        self.modelContainer = modelContainer
        self.translationService = translationService
    }

    /// Seed the database if needed, ensuring only one seeding operation runs at a time.
    func seedIfNeeded() async throws {
        if let existingTask = seedingTask {
            Self.logger.debug("Seeding already in progress, waiting for completion")
            try await existingTask.value
            return
        }

        let task = Task {
            do {
                let context = ModelContext(modelContainer)
                let translationRepository = SwiftDataTranslationRepository(
                    modelContext: context,
                    translationService: translationService
                )
                let repository = SwiftDataQuoteRepository(
                    modelContext: context,
                    translationCacheRepository: translationRepository
                )
                try repository.seedIfNeeded()
                Self.logger.info("Database seeding completed successfully")
            } catch {
                Self.logger.error("Database seeding failed: \(error.localizedDescription)")
                throw error
            }
        }

        seedingTask = task
        defer { seedingTask = nil }

        try await task.value
    }

    /// Purge quotes that were soft-deleted more than 30 days ago.
    func purgeExpiredQuotes() async {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()

        do {
            let context = ModelContext(modelContainer)
            let translationRepository = SwiftDataTranslationRepository(
                modelContext: context,
                translationService: translationService
            )
            let repository = SwiftDataQuoteRepository(
                modelContext: context,
                translationCacheRepository: translationRepository
            )
            let purgedCount = try repository.purgeDeletedQuotes(before: cutoffDate)

            if purgedCount > 0 {
                Self.logger.info("Purged \(purgedCount) expired quote(s)")
            }
        } catch {
            Self.logger.error("Failed to purge expired quotes: \(error.localizedDescription)")
        }
    }

    /// Backfill structured translation cache after seed and migration work completes.
    func backfillTranslations() async {
        if let existingTask = translationBackfillTask {
            do {
                try await existingTask.value
            } catch {
                Self.logger.error("Translation backfill task failed while awaiting existing task: \(error.localizedDescription)")
            }
            return
        }

        let task = Task(priority: .utility) {
            do {
                let context = ModelContext(modelContainer)
                let repository = SwiftDataTranslationRepository(
                    modelContext: context,
                    translationService: translationService
                )
                try repository.backfillAllQuotes()
                Self.logger.info("Translation backfill completed successfully")
            } catch {
                Self.logger.error("Translation backfill failed: \(error.localizedDescription)")
                throw error
            }
        }

        translationBackfillTask = task
        defer { translationBackfillTask = nil }

        do {
            try await task.value
        } catch {
            Self.logger.error("Translation backfill did not complete: \(error.localizedDescription)")
        }
    }
}
