//
//  ReadingPreset.swift
//  RunicQuotes
//
//  Created by Codex on 2026-02-13.
//

import Foundation

/// Curated script + font combinations for quick setup.
enum ReadingPreset: String, Codable, CaseIterable, Identifiable, Sendable {
    case elderScholar = "Elder Scholar"
    case youngerCarved = "Younger Carved"
    case cirthLore = "Cirth Lore"

    var id: String { rawValue }

    var displayName: String { rawValue }

    var script: RunicScript {
        switch self {
        case .elderScholar:
            return .elder
        case .youngerCarved:
            return .younger
        case .cirthLore:
            return .cirth
        }
    }

    var font: RunicFont {
        switch self {
        case .elderScholar:
            return .noto
        case .youngerCarved:
            return .babelstone
        case .cirthLore:
            return .cirth
        }
    }

    var description: String {
        switch self {
        case .elderScholar:
            return "Balanced for clear daily reading"
        case .youngerCarved:
            return "Sharper historical texture"
        case .cirthLore:
            return "Angerthas-inspired fantasy style"
        }
    }

    var previewLatinText: String {
        switch self {
        case .elderScholar:
            return "Wisdom walks with patience."
        case .youngerCarved:
            return "Stone remembers every oath."
        case .cirthLore:
            return "Stars guard the hidden road."
        }
    }
}
