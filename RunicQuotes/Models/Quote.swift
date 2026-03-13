//
//  Quote.swift
//  RunicQuotes
//
//  Created by Claude on 2025-11-15.
//

import Foundation
import SwiftData

/// Represents an inspirational quote with its runic transliterations
@Model
final class Quote {
    /// Unique identifier
    @Attribute(.unique) var id: UUID

    /// Original Latin text of the quote
    var textLatin: String

    /// Author of the quote
    var author: String

    /// Optional source (book, speech, etc.)
    var source: String?

    /// Explicit collection membership loaded from seed data.
    var collectionRaw: String?

    /// Precomputed Elder Futhark transliteration (optional, computed on demand if nil)
    var runicElder: String?

    /// Precomputed Younger Futhark transliteration (optional, computed on demand if nil)
    var runicYounger: String?

    /// Precomputed Cirth transliteration (optional, computed on demand if nil)
    var runicCirth: String?

    /// Timestamp when the quote was created
    var createdAt: Date

    /// Whether this is a user-generated quote (for future feature)
    var isUserGenerated: Bool

    /// Whether the quote is hidden from the main feed.
    var isHidden: Bool

    /// Whether the quote is soft-deleted (moved to archive trash).
    var isSoftDeleted: Bool

    /// Timestamp when the quote was soft-deleted (for 30-day auto-purge).
    var deletedAt: Date?

    /// Initialize a new quote
    /// - Parameters:
    ///   - textLatin: The original Latin text
    ///   - author: The author of the quote
    ///   - collection: Collection membership for faster browsing
    ///   - isUserGenerated: Whether this is user-generated content (default: false)
    init(
        textLatin: String,
        author: String,
        collection: QuoteCollection = .motivation,
        isUserGenerated: Bool = false
    ) {
        self.id = UUID()
        self.textLatin = textLatin
        self.author = author
        self.collectionRaw = collection.rawValue
        self.isUserGenerated = isUserGenerated
        self.isHidden = false
        self.isSoftDeleted = false
        self.deletedAt = nil
        self.createdAt = Date()

        // Runic translations will be computed on demand or during seeding
        self.runicElder = nil
        self.runicYounger = nil
        self.runicCirth = nil
    }

    /// Collection membership for this quote.
    var collection: QuoteCollection {
        get {
            QuoteCollection(rawValue: collectionRaw ?? "") ?? .motivation
        }
        set {
            collectionRaw = newValue.rawValue
        }
    }

    /// Get the runic text for a specific script
    /// - Parameter script: The runic script to use
    /// - Returns: The transliterated text, or nil if not yet computed
    func runicText(for script: RunicScript) -> String? {
        switch script {
        case .elder:
            return runicElder
        case .younger:
            return runicYounger
        case .cirth:
            return runicCirth
        }
    }

    /// Set the runic text for a specific script
    /// - Parameters:
    ///   - text: The transliterated text
    ///   - script: The runic script
    func setRunicText(_ text: String, for script: RunicScript) {
        switch script {
        case .elder:
            runicElder = text
        case .younger:
            runicYounger = text
        case .cirth:
            runicCirth = text
        }
    }
}

/// Extension for preview and testing
extension Quote {
    /// Create a sample quote for previews
    static var sample: Quote {
        Quote(
            textLatin: "The only way out is through.",
            author: "Robert Frost",
            collection: .motivation
        )
    }

    /// Create multiple sample quotes
    static var samples: [Quote] {
        [
            Quote(textLatin: "The only way out is through.", author: "Robert Frost", collection: .motivation),
            Quote(textLatin: "Not all those who wander are lost.", author: "J.R.R. Tolkien", collection: .tolkien),
            Quote(textLatin: "Fortune favors the bold.", author: "Virgil", collection: .stoic)
        ]
    }
}
