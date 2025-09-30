//
//  WidgetMode.swift
//  RunicQuotes
//
//  Created by Claude on 2025-11-15.
//

import Foundation

/// Determines how the widget selects quotes to display
enum WidgetMode: String, Codable, CaseIterable, Identifiable {
    case daily = "Daily"
    case random = "Random"

    var id: String { rawValue }

    /// Display name for UI
    var displayName: String {
        rawValue
    }

    /// Description of the mode
    var description: String {
        switch self {
        case .daily:
            return "Same quote for all users each day"
        case .random:
            return "Random quote on each widget refresh"
        }
    }
}
