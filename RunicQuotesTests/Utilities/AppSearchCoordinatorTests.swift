//
//  AppSearchCoordinatorTests.swift
//  RunicQuotesTests
//
//  Created by Codex on 2026-03-13.
//

import Testing
@testable import RunicQuotes

@Suite(.tags(.utility))
struct AppSearchCoordinatorTests {
    @Test
    func clearResetsQueryAndPresentationState() {
        let coordinator = AppSearchCoordinator()
        coordinator.query = "stoic"
        coordinator.isPresented = true

        coordinator.clear()

        #expect(coordinator.query.isEmpty)
        #expect(!coordinator.isPresented)
    }
}
