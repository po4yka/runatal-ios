//
//  AppTabTests.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

@testable import RunicQuotes
import SwiftUI
import Testing

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
