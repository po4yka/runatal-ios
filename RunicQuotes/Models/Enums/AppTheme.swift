//
//  AppTheme.swift
//  RunicQuotes
//
//  Created by Claude on 2025-11-15.
//

import Foundation

/// Visual theme options for the app and widget.
enum AppTheme: String, Codable, CaseIterable, Identifiable, Sendable {
    case obsidian = "Obsidian"
    case parchment = "Parchment"
    case nordicDawn = "Nordic Dawn"

    var id: String { rawValue }

    var displayName: String { rawValue }

    var description: String {
        switch self {
        case .obsidian:
            return "Dark mineral canvas with restrained liquid chrome"
        case .parchment:
            return "Warm manuscript tint with soft amber glass accents"
        case .nordicDawn:
            return "Pale atmospheric canvas with cool glass highlights"
        }
    }
}
