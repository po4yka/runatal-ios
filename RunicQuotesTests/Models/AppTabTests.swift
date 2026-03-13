//
//  AppTabTests.swift
//  RunicQuotesTests
//
//  Created by Codex on 2026-03-13.
//

import SwiftUI
import Testing
@testable import RunicQuotes

@Suite(.tags(.model))
struct AppTabTests {
    @Test
    func searchTabUsesSearchRole() {
        #expect(AppTab.search.role == .search)
        #expect(AppTab.home.role == nil)
    }

    @Test
    func onlyHomeSupportsBottomAccessory() {
        #expect(AppTab.home.supportsBottomAccessory)
        #expect(!AppTab.search.supportsBottomAccessory)
        #expect(!AppTab.settings.supportsBottomAccessory)
    }
}
