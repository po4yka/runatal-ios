//
//  DatabaseCoordinator.swift
//  RunicQuotes
//
//  Created by Claude on 2025-11-15.
//

import Foundation
import SwiftData
import os

protocol DatabaseQuoteRepository: Sendable {
    func seedIfNeeded() throws
    func purgeDeletedQuotes(before cutoffDate: Date) throws -> Int
}

protocol DatabaseTranslationRepository: Sendable {
    func backfillAllQuotes() throws
}

extension SwiftDataQuoteRepository: DatabaseQuoteRepository { }
extension SwiftDataTranslationRepository: DatabaseTranslationRepository { }

/// Thread-safe coordinator for database seeding and maintenance operations.
actor DatabaseCoordinator {
    typealias QuoteRepositoryFactory = @Sendable (ModelContext, HistoricalTranslationService) -> any DatabaseQuoteRepository
    typealias TranslationRepositoryFactory = @Sendable (ModelContext, HistoricalTranslationService)
        -> any DatabaseTranslationRepository

    private static let logger = Logger(subsystem: AppConstants.loggingSubsystem, category: "DatabaseCoordinator")

    private let modelContainer: ModelContainer
    private let translationService: HistoricalTranslationService
    private let quoteRepositoryFactory: QuoteRepositoryFactory
    private let translationRepositoryFactory: TranslationRepositoryFactory
    private var seedingTask: Task<Void, Error>?
    private var translationBackfillTask: Task<Void, Error>?

    init(
        modelContainer: ModelContainer,
        translationService: HistoricalTranslationService = HistoricalTranslationService(),
        quoteRepositoryFactory: @escaping QuoteRepositoryFactory = { context, translationService in
            let translationRepository = SwiftDataTranslationRepository(
                modelContext: context,
                translationService: translationService
            )
            return SwiftDataQuoteRepository(
                modelContext: context,
                translationCacheRepository: translationRepository
            )
        },
        translationRepositoryFactory: @escaping TranslationRepositoryFactory = { context, translationService in
            SwiftDataTranslationRepository(
                modelContext: context,
                translationService: translationService
            )
        }
    ) {
        self.modelContainer = modelContainer
        self.translationService = translationService
        self.quoteRepositoryFactory = quoteRepositoryFactory
        self.translationRepositoryFactory = translationRepositoryFactory
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
                let repository = quoteRepositoryFactory(context, translationService)
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
            let repository = quoteRepositoryFactory(context, translationService)
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
                let repository = translationRepositoryFactory(context, translationService)
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
