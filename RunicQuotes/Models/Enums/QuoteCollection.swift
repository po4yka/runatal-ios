//
//  QuoteCollection.swift
//  RunicQuotes
//
//  Created by Claude on 13.02.26.
//

import Foundation

/// Curated quote collections for faster browsing.
enum QuoteCollection: String, Codable, CaseIterable, Identifiable {
    case all = "All"
    case motivation = "Motivation"
    case stoic = "Stoic"
    case tolkien = "Tolkien"

    var id: String {
        rawValue
    }

    var displayName: String {
        rawValue
    }

    var subtitle: String {
        switch self {
        case .all:
            "Every tradition, one stream"
        case .motivation:
            "Action, courage, momentum"
        case .stoic:
            "Discipline, fate, inner order"
        case .tolkien:
            "Middle-earth voices and lore"
        }
    }

    var systemImage: String {
        switch self {
        case .all:
            "books.vertical"
        case .motivation:
            "bolt.fill"
        case .stoic:
            "building.columns.fill"
        case .tolkien:
            "leaf.fill"
        }
    }

    var heroRunicText: String {
        switch self {
        case .all:
            "ᚱᚢᚾᚨ"
        case .motivation:
            "ᛗᛟᛏ"
        case .stoic:
            "ᛋᛏᛟ"
        case .tolkien:
            "ᛏᛟᛚ"
        }
    }

    var heroLatinText: String {
        switch self {
        case .all:
            "Browse the full archive"
        case .motivation:
            "Pick up momentum"
        case .stoic:
            "Steady your mind"
        case .tolkien:
            "Walk the hidden road"
        }
    }

    func contains(_ quote: QuoteRecord) -> Bool {
        if self == .all {
            return true
        }

        return quote.collection == self
    }
}
