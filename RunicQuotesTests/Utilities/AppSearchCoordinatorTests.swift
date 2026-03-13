//
//  AppSearchCoordinatorTests.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

@testable import RunicQuotes
import Testing

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
