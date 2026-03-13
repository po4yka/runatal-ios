//
//  RunicTextBundle.swift
//  RunicQuotes
//
//  Created by Codex on 2026-03-13.
//

import Foundation

/// Explicit runic strings to persist instead of on-demand transliteration.
struct RunicTextBundle: Sendable, Codable, Equatable {
    let elder: String?
    let younger: String?
    let cirth: String?

    func text(for script: RunicScript) -> String? {
        switch script {
        case .elder:
            return elder
        case .younger:
            return younger
        case .cirth:
            return cirth
        }
    }
}
