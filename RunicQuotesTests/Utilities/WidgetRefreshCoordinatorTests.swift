//
//  WidgetRefreshCoordinatorTests.swift
//  RunicQuotes
//
//  Created by Claude on 09.10.26.
//

import Foundation
@testable import RunicQuotes
import Testing

@MainActor
@Suite(.serialized, .tags(.utility))
struct WidgetRefreshCoordinatorTests {
    @Test
    func successfulRealPreferenceAndLibraryWritesReloadWidgetTimeline() async throws {
        let context = try TestSupport.makeModelContext()
        let reloader = WidgetReloaderSpy()
        let coordinator = WidgetRefreshCoordinator(reloader: reloader)
        try SwiftDataUserPreferencesRepository(modelContext: context).apply([.theme(.nordicDawn)])
        #expect(await TestSupport.eventually { reloader.count >= 1 })
        let count = reloader.count
        _ = try SwiftDataQuoteRepository(modelContext: context).createQuote(
            textLatin: "A reading passage",
            author: "Reader",
            source: nil,
            collection: .stoic,
            storedRunic: nil,
            translations: [],
        )
        #expect(await TestSupport.eventually { reloader.count > count })
        withExtendedLifetime(coordinator) {}
    }
}

@MainActor
private final class WidgetReloaderSpy: WidgetReloading {
    var count = 0
    func reloadQuotes() {
        self.count += 1
    }
}
