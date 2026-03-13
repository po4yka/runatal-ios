//
//  AppTheme.swift
//  RunicQuotes
//
//  Created by Claude on 13.02.26.
//

import Foundation

/// Visual theme options for the app and widget.
enum AppTheme: String, Codable, CaseIterable, Identifiable {
    case obsidian = "Obsidian"
    case parchment = "Parchment"
    case nordicDawn = "Nordic Dawn"

    var id: String {
        rawValue
    }

    var displayName: String {
        rawValue
    }

    var description: String {
        switch self {
        case .obsidian:
            "Dark mineral canvas with restrained liquid chrome"
        case .parchment:
            "Warm manuscript tint with soft amber glass accents"
        case .nordicDawn:
            "Pale atmospheric canvas with cool glass highlights"
        }
    }
}
