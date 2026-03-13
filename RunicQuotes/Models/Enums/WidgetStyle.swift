//
//  WidgetStyle.swift
//  RunicQuotes
//
//  Created by Claude on 13.02.26.
//

import Foundation

/// Visual content hierarchy style for widgets.
enum WidgetStyle: String, Codable, CaseIterable, Identifiable {
    case runeFirst = "Rune-first"
    case translationFirst = "Translation-first"

    var id: String {
        rawValue
    }

    var displayName: String {
        rawValue
    }

    var description: String {
        switch self {
        case .runeFirst:
            "Runic text is the dominant element"
        case .translationFirst:
            "Latin translation is the dominant element"
        }
    }
}
