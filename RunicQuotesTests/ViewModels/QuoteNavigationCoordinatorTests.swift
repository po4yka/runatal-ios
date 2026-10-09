//
//  QuoteNavigationCoordinatorTests.swift
//  RunicQuotes
//
//  Created by Claude on 09.10.26.
//

import Foundation
@testable import RunicQuotes
import Testing

@MainActor
@Suite(.serialized, .tags(.viewModel))
struct QuoteNavigationCoordinatorTests {
    @Test
    func routeStaysPendingUntilHomeExplicitlyConsumesIt() throws {
        let coordinator = QuoteNavigationCoordinator()
        let id = UUID()
        coordinator.openQuote(id: id, script: .cirth, mode: .random, collection: .stoic)
        let pending = try #require(coordinator.pendingRequest)
        #expect(pending.id == id)
        #expect(pending.script == .cirth)
        #expect(pending.collection == .stoic)
        #expect(coordinator.consumePendingRequest() == pending)
        #expect(coordinator.consumePendingRequest() == nil)
    }

    @Test
    func latestRouteWinsBeforeHomeMountsAndDailyRouteDoesNotFreezePreferences() {
        let coordinator = QuoteNavigationCoordinator()
        coordinator.openQuote(id: UUID(), script: .cirth, mode: .random, collection: .tolkien)
        coordinator.openQuote(id: nil, script: nil, mode: .daily, collection: nil)
        let request = coordinator.consumePendingRequest()
        #expect(request?.id == nil)
        #expect(request?.script == nil)
        #expect(request?.collection == nil)
        #expect(request?.mode == .daily)
    }
}
