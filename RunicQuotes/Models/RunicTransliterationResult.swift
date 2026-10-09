//
//  RunicTransliterationResult.swift
//  RunicQuotes
//
//  Created by Claude on 09.10.26.
//

import Foundation

struct RunicTransliterationResult: Equatable, Sendable {
    let glyphOutput: String
    let unresolvedCharacters: [String]

    var warnings: [String] {
        self.unresolvedCharacters.isEmpty ? [] : [
            "Some characters could not be converted and were kept unchanged: " + self.unresolvedCharacters.joined(separator: ", "),
        ]
    }
}
