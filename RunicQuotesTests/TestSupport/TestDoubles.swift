//
//  TestDoubles.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import Foundation
@testable import RunicQuotes

struct TestError: Error, Equatable, LocalizedError {
    let message: String

    var errorDescription: String? {
        self.message
    }
}

struct CachedTranslationCall {
    let result: TranslationResult
    let quoteID: UUID
    let sourceText: String
}

final class TestPreferencesRepository: UserPreferencesRepository, @unchecked Sendable {
    private let lock = NSLock()

    var snapshotResult: Result<UserPreferencesSnapshot, Error> = .success(UserPreferencesSnapshot())
    var saveResult: Result<Void, Error> = .success(())

    private(set) var saveCalls: [UserPreferencesSnapshot] = []

    func snapshot() throws -> UserPreferencesSnapshot {
        switch self.snapshotResult {
        case .success(let snapshot):
            return snapshot
        case .failure(let error):
            throw error
        }
    }

    func save(_ snapshot: UserPreferencesSnapshot) throws {
        self.lock.withLock {
            self.saveCalls.append(snapshot)
        }

        switch self.saveResult {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }
}

final class TestTranslationRepository: TranslationRepository, @unchecked Sendable {
    private let lock = NSLock()

    var latestTranslationResults: [UUID: [RunicScript: TranslationResult]] = [:]
    var latestTranslationError: Error?
    var cacheError: Error?
    var deleteError: Error?
    var backfillError: Error?

    private(set) var cacheCalls: [CachedTranslationCall] = []
    private(set) var deleteCalls: [UUID] = []
    private(set) var backfillCallCount = 0

    func latestTranslation(for quoteID: UUID, script: RunicScript) throws -> TranslationResult? {
        if let latestTranslationError {
            throw latestTranslationError
        }
        return self.lock.withLock {
            self.latestTranslationResults[quoteID]?[script]
        }
    }

    func cache(result: TranslationResult, for quoteID: UUID, sourceText: String) throws {
        if let cacheError {
            throw cacheError
        }

        self.lock.withLock {
            self.cacheCalls.append(
                CachedTranslationCall(
                    result: result,
                    quoteID: quoteID,
                    sourceText: sourceText,
                ),
            )
            var existing = self.latestTranslationResults[quoteID] ?? [:]
            existing[result.script] = result
            self.latestTranslationResults[quoteID] = existing
        }
    }

    func cache(results: [TranslationResult], for quoteID: UUID, sourceText: String) throws {
        try results.forEach { try self.cache(result: $0, for: quoteID, sourceText: sourceText) }
    }

    func deleteTranslations(for quoteID: UUID) throws {
        if let deleteError {
            throw deleteError
        }

        self.lock.withLock {
            self.deleteCalls.append(quoteID)
            self.latestTranslationResults[quoteID] = nil
        }
    }

    func backfillAllQuotes() throws {
        if let backfillError {
            throw backfillError
        }

        self.lock.withLock {
            self.backfillCallCount += 1
        }
    }
}

final class TestQuoteRepository: QuoteRepository, @unchecked Sendable {
    private let lock = NSLock()

    var seedError: Error?
    var quoteOfTheDayError: Error?
    var randomQuoteError: Error?
    var allQuotesError: Error?
    var archivedQuotesError: Error?
    var quoteError: Error?
    var createError: Error?
    var updateError: Error?
    var hideError: Error?
    var softDeleteError: Error?
    var restoreError: Error?
    var eraseError: Error?
    var purgeError: Error?

    var quoteOfTheDayQuote = TestSupport.makeQuoteRecord()
    var randomQuoteQueue = [TestSupport.makeQuoteRecord()]
    var allQuotesValue = [QuoteRecord]()
    var archivedQuotesValue = [QuoteRecord]()
    var quoteByID = [UUID: QuoteRecord]()
    var purgeDeletedQuotesValue = 0

    private(set) var seedCallCount = 0
    private(set) var quoteOfTheDayScripts: [RunicScript] = []
    private(set) var randomQuoteScripts: [RunicScript] = []
    private(set) var allQuotesCallCount = 0
    private(set) var archivedQuotesCallCount = 0
    private(set) var createdQuotes: [QuoteRecord] = []
    private(set) var updatedQuotes: [QuoteRecord] = []
    private(set) var hiddenQuoteIDs: [UUID] = []
    private(set) var softDeletedQuoteIDs: [UUID] = []
    private(set) var restoredQuoteIDs: [UUID] = []
    private(set) var erasedQuoteIDs: [UUID] = []
    private(set) var purgeCutoffDates: [Date] = []

    func seedIfNeeded() throws {
        if let seedError {
            throw seedError
        }
        self.lock.withLock {
            self.seedCallCount += 1
        }
    }

    func quoteOfTheDay(for script: RunicScript) throws -> QuoteRecord {
        if let quoteOfTheDayError {
            throw quoteOfTheDayError
        }

        return self.lock.withLock {
            self.quoteOfTheDayScripts.append(script)
            return self.quoteOfTheDayQuote
        }
    }

    func randomQuote(for script: RunicScript) throws -> QuoteRecord {
        if let randomQuoteError {
            throw randomQuoteError
        }

        return self.lock.withLock {
            self.randomQuoteScripts.append(script)
            if !self.randomQuoteQueue.isEmpty {
                return self.randomQuoteQueue.removeFirst()
            }
            return self.quoteOfTheDayQuote
        }
    }

    func allQuotes() throws -> [QuoteRecord] {
        if let allQuotesError {
            throw allQuotesError
        }

        return self.lock.withLock {
            self.allQuotesCallCount += 1
            return self.allQuotesValue
        }
    }

    func quote(id: UUID) throws -> QuoteRecord? {
        if let quoteError {
            throw quoteError
        }
        return self.lock.withLock {
            self.quoteByID[id]
        }
    }

    func archivedQuotes() throws -> [QuoteRecord] {
        if let archivedQuotesError {
            throw archivedQuotesError
        }

        return self.lock.withLock {
            self.archivedQuotesCallCount += 1
            return self.archivedQuotesValue
        }
    }

    func createQuote(
        textLatin: String,
        author: String,
        source: String?,
        collection: QuoteCollection,
        storedRunic: RunicTextBundle?,
    ) throws -> QuoteRecord {
        if let createError {
            throw createError
        }

        let record = TestSupport.makeQuoteRecord(
            text: textLatin,
            author: author,
            source: source,
            collection: collection,
            runicElder: storedRunic?.elder,
            runicYounger: storedRunic?.younger,
            runicCirth: storedRunic?.cirth,
            isUserGenerated: true,
        )

        return self.lock.withLock {
            self.createdQuotes.append(record)
            self.quoteByID[record.id] = record
            return record
        }
    }

    // swiftlint:disable:next function_parameter_count
    func updateQuote(
        id: UUID,
        textLatin: String,
        author: String,
        source: String?,
        collection: QuoteCollection,
        storedRunic: RunicTextBundle?,
    ) throws -> QuoteRecord {
        if let updateError {
            throw updateError
        }

        let record = TestSupport.makeQuoteRecord(
            id: id,
            text: textLatin,
            author: author,
            source: source,
            collection: collection,
            runicElder: storedRunic?.elder,
            runicYounger: storedRunic?.younger,
            runicCirth: storedRunic?.cirth,
            isUserGenerated: true,
        )

        return self.lock.withLock {
            self.updatedQuotes.append(record)
            self.quoteByID[id] = record
            return record
        }
    }

    func hideQuote(id: UUID) throws -> QuoteRecord {
        if let hideError {
            throw hideError
        }

        return self.lock.withLock {
            self.hiddenQuoteIDs.append(id)
            let existing = self.quoteByID[id] ?? TestSupport.makeQuoteRecord(id: id)
            let record = TestSupport.makeQuoteRecord(
                id: existing.id,
                text: existing.textLatin,
                author: existing.author,
                source: existing.source,
                collection: existing.collection,
                runicElder: existing.runicElder,
                runicYounger: existing.runicYounger,
                runicCirth: existing.runicCirth,
                createdAt: existing.createdAt,
                isHidden: true,
                isDeleted: false,
                deletedAt: nil,
                isUserGenerated: existing.isUserGenerated,
            )
            self.quoteByID[id] = record
            return record
        }
    }

    func softDeleteQuote(id: UUID, deletedAt: Date) throws -> QuoteRecord {
        if let softDeleteError {
            throw softDeleteError
        }

        return self.lock.withLock {
            self.softDeletedQuoteIDs.append(id)
            let existing = self.quoteByID[id] ?? TestSupport.makeQuoteRecord(id: id)
            let record = TestSupport.makeQuoteRecord(
                id: existing.id,
                text: existing.textLatin,
                author: existing.author,
                source: existing.source,
                collection: existing.collection,
                runicElder: existing.runicElder,
                runicYounger: existing.runicYounger,
                runicCirth: existing.runicCirth,
                createdAt: existing.createdAt,
                isHidden: existing.isHidden,
                isDeleted: true,
                deletedAt: deletedAt,
                isUserGenerated: existing.isUserGenerated,
            )
            self.quoteByID[id] = record
            return record
        }
    }

    func restoreQuote(id: UUID) throws -> QuoteRecord {
        if let restoreError {
            throw restoreError
        }

        return self.lock.withLock {
            self.restoredQuoteIDs.append(id)
            let existing = self.quoteByID[id] ?? TestSupport.makeQuoteRecord(id: id)
            let record = TestSupport.makeQuoteRecord(
                id: existing.id,
                text: existing.textLatin,
                author: existing.author,
                source: existing.source,
                collection: existing.collection,
                runicElder: existing.runicElder,
                runicYounger: existing.runicYounger,
                runicCirth: existing.runicCirth,
                createdAt: existing.createdAt,
                isHidden: false,
                isDeleted: false,
                deletedAt: nil,
                isUserGenerated: existing.isUserGenerated,
            )
            self.quoteByID[id] = record
            return record
        }
    }

    func eraseQuote(id: UUID) throws {
        if let eraseError {
            throw eraseError
        }

        self.lock.withLock {
            self.erasedQuoteIDs.append(id)
            self.quoteByID[id] = nil
        }
    }

    func purgeDeletedQuotes(before cutoffDate: Date) throws -> Int {
        if let purgeError {
            throw purgeError
        }

        return self.lock.withLock {
            self.purgeCutoffDates.append(cutoffDate)
            return self.purgeDeletedQuotesValue
        }
    }
}

private extension NSLock {
    func withLock<T>(_ work: () -> T) -> T {
        self.lock()
        defer { self.unlock() }
        return work()
    }
}
