//
//  AppTab.swift
//  RunicQuotes
//
//  Created by Claude on 2026-03-12.
//

import SwiftUI

/// Tab destinations for the main tab bar.
enum AppTab: String, Codable, CaseIterable, Identifiable, Sendable {
    case home
    case collections
    case search
    case saved
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: return "Home"
        case .collections: return "Collections"
        case .search: return "Search"
        case .saved: return "Saved"
        case .settings: return "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .home: return "house"
        case .collections: return "square.grid.2x2"
        case .search: return "magnifyingglass"
        case .saved: return "bookmark"
        case .settings: return "gear"
        }
    }

    var accessibilityID: String {
        "\(rawValue)_tab"
    }
}
