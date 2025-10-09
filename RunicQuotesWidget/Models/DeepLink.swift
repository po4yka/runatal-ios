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
            return URL(string: "runicquotes://")!
        case .openQuote(let script):
            return URL(string: "runicquotes://quote?script=\(script.rawValue)")!
        case .openSettings:
            return URL(string: "runicquotes://settings")!
        case .nextQuote:
            return URL(string: "runicquotes://next")!
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
