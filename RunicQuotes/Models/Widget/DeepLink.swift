//
//  DeepLink.swift
//  RunicQuotes
//
//  Created by Codex on 2026-03-13.
//

import Foundation

/// Deep link URLs shared between the widget and the app.
enum DeepLink: Equatable, Sendable {
    case openApp
    case openQuote(script: RunicScript, mode: WidgetMode)
    case openSettings
    case nextQuote

    var url: URL {
        switch self {
        case .openApp:
            guard let url = URL(string: "\(AppConstants.urlScheme)://") else {
                preconditionFailure("Invalid hardcoded URL scheme")
            }
            return url

        case .openQuote(let script, let mode):
            var components = URLComponents()
            components.scheme = AppConstants.urlScheme
            components.host = "quote"
            components.queryItems = [
                URLQueryItem(name: "script", value: script.rawValue),
                URLQueryItem(name: "mode", value: mode.rawValue)
            ]

            guard let url = components.url else {
                preconditionFailure("Failed to construct quote deep link")
            }
            return url

        case .openSettings:
            guard let url = URL(string: "\(AppConstants.urlScheme)://settings") else {
                preconditionFailure("Invalid settings URL")
            }
            return url

        case .nextQuote:
            guard let url = URL(string: "\(AppConstants.urlScheme)://next") else {
                preconditionFailure("Invalid next-quote URL")
            }
            return url
        }
    }

    static func from(url: URL) -> DeepLink? {
        guard url.scheme == AppConstants.urlScheme else {
            return nil
        }

        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)

        switch url.host {
        case "quote":
            guard
                let scriptRaw = components?.queryItems?.first(where: { $0.name == "script" })?.value,
                let script = RunicScript(rawValue: scriptRaw)
            else {
                return .openApp
            }

            let modeRaw = components?.queryItems?.first(where: { $0.name == "mode" })?.value
            let mode = WidgetMode(rawValue: modeRaw ?? "") ?? .daily
            return .openQuote(script: script, mode: mode)

        case "settings":
            return .openSettings

        case "next":
            return .nextQuote

        default:
            return .openApp
        }
    }
}
