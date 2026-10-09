//
//  QuoteInputValidation.swift
//  RunicQuotes
//
//  Created by Claude on 09.10.26.
//

import Foundation

enum QuoteInputValidation {
    static func validate(text: String, author: String, collection: QuoteCollection) throws {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw QuoteInputError.emptyText }
        guard text.count <= AppConstants.maxQuoteLength else { throw QuoteInputError.textTooLong }
        guard !author.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw QuoteInputError.emptyAuthor }
        guard collection != .all else { throw QuoteInputError.invalidCollection }
    }
}

enum QuoteInputError: LocalizedError {
    case emptyText
    case textTooLong
    case emptyAuthor
    case invalidCollection

    var errorDescription: String? {
        switch self {
        case .emptyText: "Quote text is required."
        case .textTooLong: "Quote text must be at most \(AppConstants.maxQuoteLength) characters. Your text has been preserved."
        case .emptyAuthor: "Author name is required."
        case .invalidCollection: "Choose a quote collection. All is a library filter."
        }
    }
}

enum TranslationInputError: LocalizedError {
    case textTooLong

    var errorDescription: String? {
        "Translation input must be at most \(AppConstants.maxTranslationInputLength) characters. Your text has been preserved."
    }
}
