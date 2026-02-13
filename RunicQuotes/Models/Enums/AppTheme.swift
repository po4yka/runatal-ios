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
            return "High-contrast dark glass with deep mineral tones"
        case .parchment:
            return "Warm sepia glow inspired by aged manuscripts"
        case .nordicDawn:
            return "Cool arctic gradient with misty morning blues"
        }
    }
}
