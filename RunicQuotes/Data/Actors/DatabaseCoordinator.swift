//
//  DatabaseCoordinator.swift
//  RunicQuotes
//
//  Created by Claude on 14.11.25.
//

import Foundation
import os
import SwiftData

protocol DatabaseQuoteRepository: Sendable {
    func seedIfNeeded() throws
    func purgeDeletedQuotes(before cutoffDate: Date) throws -> Int
}

protocol DatabaseTranslationRepository: Sendable {
    func backfillAllQuotes() async throws
}

extension SwiftDataQuoteRepository: DatabaseQuoteRepository {}
extension SwiftDataTranslationRepository: DatabaseTranslationRepository {}

/// Thread-safe coordinator for database seeding and maintenance operations.
@ModelActor
actor DatabaseCoordinator {
    typealias QuoteRepositoryFactory = @Sendable (ModelContext, HistoricalTranslationService) -> any DatabaseQuoteRepository
    typealias TranslationRepositoryFactory = @Sendable (ModelContext, HistoricalTranslationService)
        -> any DatabaseTranslationRepository

    private static let logger = Logger(subsystem: AppConstants.loggingSubsystem, category: "DatabaseCoordinator")

    private static let defaultQuoteRepositoryFactory: QuoteRepositoryFactory = { context, _ in
        SwiftDataQuoteRepository(modelContext: context)

    }

    private static let defaultTranslationRepositoryFactory: TranslationRepositoryFactory = { context, translationService in
        SwiftDataTranslationRepository(
            modelContext: context,
            translationService: translationService,
        )
    }

    private var translationService = HistoricalTranslationService()
    private var quoteRepositoryFactory: QuoteRepositoryFactory = DatabaseCoordinator.defaultQuoteRepositoryFactory
    private var translationRepositoryFactory: TranslationRepositoryFactory = DatabaseCoordinator.defaultTranslationRepositoryFactory
    private var hasSeeded = false
    private var seedingTask: Task<Void, Error>?
    private var translationBackfillTask: Task<Void, Error>?

    init(
        modelContainer: ModelContainer,
        translationService: HistoricalTranslationService = HistoricalTranslationService(),
        quoteRepositoryFactory: @escaping QuoteRepositoryFactory = DatabaseCoordinator.defaultQuoteRepositoryFactory,
        translationRepositoryFactory: @escaping TranslationRepositoryFactory = DatabaseCoordinator.defaultTranslationRepositoryFactory,
    ) {
        let context = ModelContext(modelContainer)
        self.modelExecutor = DefaultSerialModelExecutor(modelContext: context)
        self.modelContainer = modelContainer
        self.translationService = translationService
        self.quoteRepositoryFactory = quoteRepositoryFactory
        self.translationRepositoryFactory = translationRepositoryFactory
    }

    /// Seed successfully once per coordinator lifetime, coalescing in-flight requests and retrying failures.
    func seedIfNeeded() async throws {
        guard !self.hasSeeded else { return }

        if let existingTask = seedingTask {
            Self.logger.debug("Seeding already in progress, waiting for completion")
            try await existingTask.value
            return
        }

        let task = Task {
            do {
                let repository = self.quoteRepositoryFactory(self.modelContext, self.translationService)
                try repository.seedIfNeeded()
                self.hasSeeded = true
                Self.logger.info("Database seeding completed successfully")
            } catch {
                self.modelContext.rollback()
                Self.logger.error("Database seeding failed: \(error.localizedDescription)")
                throw error
            }
        }

        self.seedingTask = task
        defer { seedingTask = nil }

        try await task.value
    }

    /// Purge quotes that were soft-deleted more than 30 days ago.
    func purgeExpiredQuotes() async throws {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()

        do {
            let repository = self.quoteRepositoryFactory(self.modelContext, self.translationService)
            let purgedCount = try repository.purgeDeletedQuotes(before: cutoffDate)

            if purgedCount > 0 {
                Self.logger.info("Purged \(purgedCount) expired quote(s)")
            }
        } catch {
            self.modelContext.rollback()
            Self.logger.error("Failed to purge expired quotes: \(error.localizedDescription)")
            throw error
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
                let repository = self.translationRepositoryFactory(self.modelContext, self.translationService)
                try await repository.backfillAllQuotes()
                Self.logger.info("Translation backfill completed successfully")
            } catch {
                self.modelContext.rollback()
                Self.logger.error("Translation backfill failed: \(error.localizedDescription)")
                throw error
            }
        }

        self.translationBackfillTask = task
        defer { translationBackfillTask = nil }

        do {
            try await task.value
        } catch {
            Self.logger.error("Translation backfill did not complete: \(error.localizedDescription)")
        }
    }
}
