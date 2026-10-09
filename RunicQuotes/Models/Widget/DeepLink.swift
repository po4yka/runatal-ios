//
//  DeepLink.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import Foundation

/// Deep link URLs shared between the widget and the app.
enum DeepLink: Equatable {
    case openApp
    case openQuote(id: UUID, script: RunicScript, mode: WidgetMode, collection: QuoteCollection)
    case openDailyQuote(script: RunicScript?)
    case openSettings
    case nextQuote

    var url: URL {
        switch self {
        case .openApp:
            guard let url = URL(string: "\(AppConstants.urlScheme)://") else {
                preconditionFailure("Invalid hardcoded URL scheme")
            }
            return url

        case .openQuote(let id, let script, let mode, let collection):
            var components = URLComponents()
            components.scheme = AppConstants.urlScheme
            components.host = "quote"
            components.queryItems = [
                URLQueryItem(name: "id", value: id.uuidString),
                URLQueryItem(name: "script", value: script.rawValue),
                URLQueryItem(name: "mode", value: mode.rawValue),
                URLQueryItem(name: "collection", value: collection.rawValue),
            ]

            guard let url = components.url else {
                preconditionFailure("Failed to construct quote deep link")
            }
            return url

        case .openDailyQuote(let script):
            var components = URLComponents()
            components.scheme = AppConstants.urlScheme
            components.host = "daily"
            components.queryItems = script.map { [URLQueryItem(name: "script", value: $0.rawValue)] }
            guard let url = components.url else { preconditionFailure("Invalid daily quote URL") }
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
                let idRaw = components?.queryItems?.first(where: { $0.name == "id" })?.value,
                let id = UUID(uuidString: idRaw),
                let scriptRaw = components?.queryItems?.first(where: { $0.name == "script" })?.value,
                let script = RunicScript(rawValue: scriptRaw)
            else {
                return nil
            }

            let modeRaw = components?.queryItems?.first(where: { $0.name == "mode" })?.value
            let mode = WidgetMode(rawValue: modeRaw ?? "") ?? .daily
            let collectionRaw = components?.queryItems?.first(where: { $0.name == "collection" })?.value
            guard let collection = collectionRaw.flatMap(QuoteCollection.init(rawValue:)) else { return nil }
            return .openQuote(id: id, script: script, mode: mode, collection: collection)

        case "daily":
            let raw = components?.queryItems?.first(where: { $0.name == "script" })?.value
            if let raw, RunicScript(rawValue: raw) == nil {
                return nil
            }
            return .openDailyQuote(script: raw.flatMap(RunicScript.init(rawValue:)))

        case "settings":
            return .openSettings

        case "next":
            return .nextQuote

        default:
            return .openApp
        }
    }
}
