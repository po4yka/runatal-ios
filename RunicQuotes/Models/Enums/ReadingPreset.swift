//
//  ReadingPreset.swift
//  RunicQuotes
//
//  Created by Claude on 13.02.26.
//

import Foundation

/// Curated script + font combinations for quick setup.
enum ReadingPreset: String, Codable, CaseIterable, Identifiable {
    case elderScholar = "Elder Scholar"
    case youngerCarved = "Younger Carved"
    case cirthLore = "Cirth Lore"

    var id: String {
        rawValue
    }

    var displayName: String {
        rawValue
    }

    var script: RunicScript {
        switch self {
        case .elderScholar:
            .elder
        case .youngerCarved:
            .younger
        case .cirthLore:
            .cirth
        }
    }

    var font: RunicFont {
        switch self {
        case .elderScholar:
            .noto
        case .youngerCarved:
            .babelstone
        case .cirthLore:
            .cirth
        }
    }

    var description: String {
        switch self {
        case .elderScholar:
            "Balanced for clear daily reading"
        case .youngerCarved:
            "Sharper historical texture"
        case .cirthLore:
            "Angerthas-inspired fantasy style"
        }
    }

    var previewLatinText: String {
        switch self {
        case .elderScholar:
            "Wisdom walks with patience."
        case .youngerCarved:
            "Stone remembers every oath."
        case .cirthLore:
            "Stars guard the hidden road."
        }
    }
}
