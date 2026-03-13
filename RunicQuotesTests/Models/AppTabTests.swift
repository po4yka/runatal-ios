//
//  AppTabTests.swift
//  RunicQuotesTests
//
//  Created by Codex on 2026-03-13.
//

import XCTest
import SwiftUI
@testable import RunicQuotes

final class AppTabTests: XCTestCase {
    func testSearchTabUsesSearchRole() {
        XCTAssertEqual(AppTab.search.role, .search)
        XCTAssertNil(AppTab.home.role)
    }

    func testOnlyHomeSupportsBottomAccessory() {
        XCTAssertTrue(AppTab.home.supportsBottomAccessory)
        XCTAssertFalse(AppTab.search.supportsBottomAccessory)
        XCTAssertFalse(AppTab.settings.supportsBottomAccessory)
    }
}
