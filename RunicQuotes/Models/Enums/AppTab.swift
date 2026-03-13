//
//  AppTab.swift
//  RunicQuotes
//
//  Created by Claude on 12.03.26.
//

import SwiftUI

/// Tab destinations for the main tab bar.
enum AppTab: String, Codable, CaseIterable, Identifiable {
    case home
    case collections
    case search
    case saved
    case settings

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .home: "Home"
        case .collections: "Collections"
        case .search: "Search"
        case .saved: "Saved"
        case .settings: "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .home: "house"
        case .collections: "square.grid.2x2"
        case .search: "magnifyingglass"
        case .saved: "bookmark"
        case .settings: "gear"
        }
    }

    var role: TabRole? {
        switch self {
        case .search:
            .search
        default:
            nil
        }
    }

    var supportsBottomAccessory: Bool {
        self == .home
    }

    var accessibilityID: String {
        "\(rawValue)_tab"
    }
}
