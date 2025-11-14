//
//  DeepLink.swift
//  RunicQuotesWidget
//
//  Created by Claude on 2025-11-15.
//

import Foundation

/// Deep link URLs for widget interactions
enum DeepLink {
    case openApp
    case openQuote(script: RunicScript)
    case openSettings
    case nextQuote

    /// Generate URL for the deep link
    var url: URL {
        switch self {
        case .openApp:
            guard let url = URL(string: "runicquotes://") else {
                preconditionFailure("Invalid hardcoded URL")
            }
            return url

        case .openQuote(let script):
            var components = URLComponents()
            components.scheme = "runicquotes"
            components.host = "quote"
            components.queryItems = [URLQueryItem(name: "script", value: script.rawValue)]

            guard let url = components.url else {
                preconditionFailure("Failed to construct URL for script: \(script.rawValue)")
            }
            return url

        case .openSettings:
            guard let url = URL(string: "runicquotes://settings") else {
                preconditionFailure("Invalid hardcoded URL")
            }
            return url

        case .nextQuote:
            guard let url = URL(string: "runicquotes://next") else {
                preconditionFailure("Invalid hardcoded URL")
            }
            return url
        }
    }

    /// Parse deep link from URL
    static func from(url: URL) -> DeepLink? {
        guard url.scheme == "runicquotes" else { return nil }

        let host = url.host
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)

        switch host {
        case "quote":
            if let scriptParam = components?.queryItems?.first(where: { $0.name == "script" })?.value,
               let script = RunicScript(rawValue: scriptParam) {
                return .openQuote(script: script)
            }
            return .openApp
        case "settings":
            return .openSettings
        case "next":
            return .nextQuote
        default:
            return .openApp
        }
    }
}
