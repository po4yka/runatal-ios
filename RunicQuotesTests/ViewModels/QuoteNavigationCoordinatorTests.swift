//
//  QuoteNavigationCoordinatorTests.swift
//  RunicQuotes
//
//  Created by Claude on 09.10.26.
//

import Combine
import Foundation
@testable import RunicQuotes
import Testing

@MainActor
@Suite(.serialized, .tags(.viewModel))
struct QuoteNavigationCoordinatorTests {
    @Test
    func emptyConsumptionDoesNotPublishAnotherPendingRequest() {
        let coordinator = QuoteNavigationCoordinator()
        var publications: [QuoteNavigationRequest?] = []
        let observation = coordinator.$pendingRequest.dropFirst().sink { request in
            publications.append(request)
        }
        defer { observation.cancel() }

        #expect(coordinator.consumePendingRequest() == nil)
        #expect(publications.isEmpty)
    }

    @Test
    func aPendingRoutePublishesItsConsumptionOnlyOnce() throws {
        let coordinator = QuoteNavigationCoordinator()
        var publications: [QuoteNavigationRequest?] = []
        let observation = coordinator.$pendingRequest.dropFirst().sink { request in
            publications.append(request)
        }
        defer { observation.cancel() }

        coordinator.openQuote(id: UUID(), script: .cirth, mode: .random, collection: .stoic)
        let request = try #require(coordinator.pendingRequest)
        #expect(coordinator.consumePendingRequest() == request)
        #expect(coordinator.consumePendingRequest() == nil)
        #expect(publications == [request, nil])
    }

    @Test
    func homeSubscriberDoesNotFeedEmptyConsumptionBackIntoItself() {
        let coordinator = QuoteNavigationCoordinator()
        var callbacks = 0
        let observation = coordinator.$pendingRequest.receive(on: RunLoop.main).sink { _ in
            callbacks += 1
            // Bound a broken feedback loop so this regression fails instead of hanging the suite.
            if callbacks <= 3 {
                _ = coordinator.consumePendingRequest()
            }
        }
        defer { observation.cancel() }

        RunLoop.main.run(until: Date().addingTimeInterval(0.1))
        #expect(callbacks == 1)
    }

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
