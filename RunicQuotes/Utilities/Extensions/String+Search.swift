//
//  String+Search.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import Foundation

extension String {
    func matchesSearchQuery(_ query: String) -> Bool {
        localizedStandardContains(query)
    }
}
