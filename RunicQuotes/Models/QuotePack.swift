//
//  QuotePack.swift
//  RunicQuotes
//
//  Created by Claude on 12.03.26.
//

import Foundation

/// A curated pack of quotes that can be browsed and installed.
struct QuotePack: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let description: String
    let runicGlyph: String
    let quoteCount: Int
    let previewQuotes: [String]

    /// Whether this pack corresponds to an existing `QuoteCollection`.
    var matchingCollection: QuoteCollection? {
        switch self.id {
        case "havamal": nil
        case "meditations": .motivation
        case "poetic-edda": nil
        case "stoic-letters": .stoic
        case "prose-edda": nil
        default: nil
        }
    }
}

// MARK: - Catalog

extension QuotePack {
    /// All available quote packs in the catalog.
    static let catalog: [QuotePack] = [
        QuotePack(
            id: "havamal",
            title: "Havamal Selections",
            subtitle: "Sayings of the High One",
            description: "Ancient Norse wisdom poems attributed to Odin, offering guidance on survival, knowledge, and the values of the Viking age.",
            runicGlyph: "\u{16BA}",
            quoteCount: 32,
            previewQuotes: [
                "Cattle die, kinsmen die, you yourself will also die.",
                "The foolish man thinks he will live forever if he avoids battle.",
                "Better a humble house than none; everyone is somebody at home.",
                "A man should be loyal through life to friends.",
            ],
        ),
        QuotePack(
            id: "meditations",
            title: "Meditations",
            subtitle: "Marcus Aurelius",
            description: "Personal reflections by the Roman Emperor on Stoic philosophy, self-discipline, and the nature of virtue.",
            runicGlyph: "\u{16D7}",
            quoteCount: 48,
            previewQuotes: [
                "You have power over your mind, not outside events. Realize this, and you will find strength.",
                "The happiness of your life depends upon the quality of your thoughts.",
                "Waste no more time arguing about what a good man should be. Be one.",
                "Very little is needed to make a happy life; it is all within yourself.",
            ],
        ),
        QuotePack(
            id: "poetic-edda",
            title: "Poetic Edda",
            subtitle: "Norse cosmology & myth",
            description: "The primary source of Norse mythology, containing poems about the creation of the world, the gods, and Ragnarok.",
            runicGlyph: "\u{16C8}",
            quoteCount: 24,
            previewQuotes: [
                "I know that I hung on a wind-battered tree, nine long nights.",
                "From the south the sun, by the side of the moon, heaved her right hand over heaven's rim.",
                "Brothers will fight and kill each other, cousins will break the bonds of kinship.",
                "An ash I know, Yggdrasil its name, with water white is the great tree wet.",
            ],
        ),
        QuotePack(
            id: "stoic-letters",
            title: "Stoic Letters",
            subtitle: "Seneca to Lucilius",
            description: "Moral letters from the Stoic philosopher Seneca to his friend Lucilius, covering wealth, time, friendship, and virtue.",
            runicGlyph: "\u{16CB}",
            quoteCount: 36,
            previewQuotes: [
                "It is not that we have a short time to live, but that we waste a great deal of it.",
                "We suffer more often in imagination than in reality.",
                "Luck is what happens when preparation meets opportunity.",
                "Difficulties strengthen the mind, as labor does the body.",
            ],
        ),
        QuotePack(
            id: "prose-edda",
            title: "Prose Edda",
            subtitle: "Snorri Sturluson",
            description: "A medieval handbook of Norse mythology and poetics, compiled by the Icelandic scholar Snorri Sturluson.",
            runicGlyph: "\u{16C8}",
            quoteCount: 20,
            previewQuotes: [
                "In the beginning there was nothing: neither sand, nor sea, nor cooling waves.",
                "The wolf will devour the sun, and mankind will consider that a great disaster.",
                "There is much to be told, and it is far to seek.",
                "The earth will rise again out of the sea, fair and green.",
            ],
        ),
    ]

    /// Sample pack for previews.
    static var sample: QuotePack {
        catalog[0]
    }
}

// MARK: - Equatable & Hashable

extension QuotePack {
    static func == (lhs: QuotePack, rhs: QuotePack) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
}
