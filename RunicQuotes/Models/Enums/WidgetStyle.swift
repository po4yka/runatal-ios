//
//  WidgetStyle.swift
//  RunicQuotes
//
//  Created by Codex on 2026-02-13.
//

import Foundation

/// Visual content hierarchy style for widgets.
enum WidgetStyle: String, Codable, CaseIterable, Identifiable, Sendable {
    case runeFirst = "Rune-first"
    case translationFirst = "Translation-first"

    var id: String { rawValue }

    var displayName: String { rawValue }

    var description: String {
        switch self {
        case .runeFirst:
            return "Runic text is the dominant element"
        case .translationFirst:
            return "Latin translation is the dominant element"
        }
    }
}
