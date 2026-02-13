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
    case openQuote(script: RunicScript, mode: WidgetMode)
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

        case .openQuote(let script, let mode):
            var components = URLComponents()
            components.scheme = "runicquotes"
            components.host = "quote"
            components.queryItems = [
                URLQueryItem(name: "script", value: script.rawValue),
                URLQueryItem(name: "mode", value: mode.rawValue)
            ]

            guard let url = components.url else {
                preconditionFailure("Failed to construct URL for script/mode: \(script.rawValue)/\(mode.rawValue)")
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
                let modeParam = components?.queryItems?.first(where: { $0.name == "mode" })?.value
                let mode = WidgetMode(rawValue: modeParam ?? "") ?? .daily
                return .openQuote(script: script, mode: mode)
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
