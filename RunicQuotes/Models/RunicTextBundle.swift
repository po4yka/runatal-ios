//
//  RunicTextBundle.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import Foundation

/// Explicit runic strings to persist instead of on-demand transliteration.
struct RunicTextBundle: Codable, Equatable {
    let elder: String?
    let younger: String?
    let cirth: String?

    func text(for script: RunicScript) -> String? {
        switch script {
        case .elder:
            self.elder
        case .younger:
            self.younger
        case .cirth:
            self.cirth
        }
    }
}
