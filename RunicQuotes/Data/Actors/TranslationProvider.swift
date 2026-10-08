//
//  TranslationProvider.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import Foundation
import SwiftData

/// Serializes translation operations on its own SwiftData context and model executor.
@ModelActor
actor TranslationProvider {
    typealias RepositoryFactory = @Sendable (ModelContext) -> any TranslationRepository

    private var repositoryFactory: RepositoryFactory = { context in
        SwiftDataTranslationRepository(modelContext: context)
    }

    private lazy var repository: any TranslationRepository = self.repositoryFactory(self.modelContext)

    init(modelContainer: ModelContainer, repositoryFactory: @escaping RepositoryFactory) {
        let context = ModelContext(modelContainer)
        self.modelContainer = modelContainer
        self.modelExecutor = DefaultSerialModelExecutor(modelContext: context)
        self.repositoryFactory = repositoryFactory
    }

    func latestTranslation(for quoteID: UUID, script: RunicScript) throws -> TranslationResult? {
        try self.repository.latestTranslation(for: quoteID, script: script)
    }

    func cache(result: TranslationResult, for quoteID: UUID, sourceText: String) throws {
        try self.repository.cache(result: result, for: quoteID, sourceText: sourceText)
    }

    func cache(results: [TranslationResult], for quoteID: UUID, sourceText: String) throws {
        try self.repository.cache(results: results, for: quoteID, sourceText: sourceText)
    }

    func deleteTranslations(for quoteID: UUID) throws {
        try self.repository.deleteTranslations(for: quoteID)
    }

    func backfillAllQuotes() throws {
        try self.repository.backfillAllQuotes()
    }
}
