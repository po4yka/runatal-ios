//
//  QuoteCollection.swift
//  RunicQuotes
//
//  Created by Codex on 2026-02-13.
//

import Foundation

/// Curated quote collections for faster browsing.
enum QuoteCollection: String, Codable, CaseIterable, Identifiable, Sendable {
    case all = "All"
    case motivation = "Motivation"
    case stoic = "Stoic"
    case tolkien = "Tolkien"

    var id: String { rawValue }

    var displayName: String { rawValue }

    var subtitle: String {
        switch self {
        case .all:
            return "Every tradition, one stream"
        case .motivation:
            return "Action, courage, momentum"
        case .stoic:
            return "Discipline, fate, inner order"
        case .tolkien:
            return "Middle-earth voices and lore"
        }
    }

    var systemImage: String {
        switch self {
        case .all:
            return "books.vertical"
        case .motivation:
            return "bolt.fill"
        case .stoic:
            return "building.columns.fill"
        case .tolkien:
            return "leaf.fill"
        }
    }

    var heroRunicText: String {
        switch self {
        case .all:
            return "ᚱᚢᚾᚨ"
        case .motivation:
            return "ᛗᛟᛏ"
        case .stoic:
            return "ᛋᛏᛟ"
        case .tolkien:
            return "ᛏᛟᛚ"
        }
    }

    var heroLatinText: String {
        switch self {
        case .all:
            return "Browse the full archive"
        case .motivation:
            return "Pick up momentum"
        case .stoic:
            return "Steady your mind"
        case .tolkien:
            return "Walk the hidden road"
        }
    }

    func contains(_ quote: QuoteRecord) -> Bool {
        if self == .all {
            return true
        }

        return quote.collection == self
    }
}
