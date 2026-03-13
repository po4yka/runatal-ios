//
//  AppSearchCoordinatorTests.swift
//  RunicQuotesTests
//
//  Created by Codex on 2026-03-13.
//

import XCTest
@testable import RunicQuotes

final class AppSearchCoordinatorTests: XCTestCase {
    func testClearResetsQueryAndPresentationState() {
        let coordinator = AppSearchCoordinator()
        coordinator.query = "stoic"
        coordinator.isPresented = true

        coordinator.clear()

        XCTAssertEqual(coordinator.query, "")
        XCTAssertFalse(coordinator.isPresented)
    }
}
