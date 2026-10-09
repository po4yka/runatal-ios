//
//  ReadingLibrarySnapshotTests.swift
//  RunicQuotes
//
//  Created by Claude on 09.10.26.
//

import Foundation
@testable import RunicQuotes
import Testing

@MainActor
@Suite(.serialized, .tags(.repository))
struct ReadingLibrarySnapshotTests {
    @Test
    func concurrentArchiveTransitionsRemainOneRecordPerIdentityInEachSnapshot() async throws {
        let context = try TestSupport.makeModelContext()
        let repository = SwiftDataQuoteRepository(modelContext: context)
        let visible = try repository.createQuote(textLatin: "A visible passage", author: "Reader", source: nil, collection: .stoic)
        let changing = try repository.createQuote(textLatin: "An archived passage", author: "Reader", source: nil, collection: .stoic)
        let provider = QuoteProvider(modelContainer: context.container)
        async let transitions: Void = self.moveBetweenVisibleAndArchive(id: changing.id, provider: provider)
        for _ in 0 ..< 30 {
            let snapshot = try await provider.readingLibraryQuotes()
            #expect(snapshot.count == 2)
            #expect(Set(snapshot.map(\.id)) == [visible.id, changing.id])
        }
        try await transitions
        _ = try await provider.softDeleteQuote(id: changing.id)
        let deletedSnapshot = try await provider.readingLibraryQuotes()
        #expect(deletedSnapshot.count == 2)
        #expect(deletedSnapshot.first(where: { $0.id == changing.id })?.isDeleted == true)
    }

    private func moveBetweenVisibleAndArchive(id: UUID, provider: QuoteProvider) async throws {
        for _ in 0 ..< 20 {
            _ = try await provider.hideQuote(id: id)
            _ = try await provider.restoreQuote(id: id)
        }
    }
}
