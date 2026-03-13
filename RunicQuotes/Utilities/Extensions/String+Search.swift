//
//  String+Search.swift
//  RunicQuotes
//
//  Created by Codex on 2026-03-13.
//

import Foundation

extension String {
    func matchesSearchQuery(_ query: String) -> Bool {
        localizedStandardContains(query)
    }
}
