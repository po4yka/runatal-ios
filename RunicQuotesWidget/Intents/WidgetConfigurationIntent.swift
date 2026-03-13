//
//  WidgetConfigurationIntent.swift
//  RunicQuotes
//
//  Created by Claude on 12.03.26.
//

import AppIntents
import WidgetKit

// MARK: - AppEnum Conformances

/// Runic script selection for widget configuration
enum ScriptOption: String, AppEnum {
    case elder
    case younger
    case cirth

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Script"
    }

    static var caseDisplayRepresentations: [ScriptOption: DisplayRepresentation] {
        [
            .elder: "Elder Futhark",
            .younger: "Younger Futhark",
            .cirth: "Cirth",
        ]
    }

    var toRunicScript: RunicScript {
        switch self {
        case .elder: .elder
        case .younger: .younger
        case .cirth: .cirth
        }
    }

    init(from script: RunicScript) {
        switch script {
        case .elder: self = .elder
        case .younger: self = .younger
        case .cirth: self = .cirth
        }
    }
}

/// Widget mode selection for widget configuration
enum ModeOption: String, AppEnum {
    case daily
    case random

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Mode"
    }

    static var caseDisplayRepresentations: [ModeOption: DisplayRepresentation] {
        [
            .daily: "Daily Quote",
            .random: "Random Quote",
        ]
    }

    var toWidgetMode: WidgetMode {
        switch self {
        case .daily: .daily
        case .random: .random
        }
    }

    init(from mode: WidgetMode) {
        switch mode {
        case .daily: self = .daily
        case .random: self = .random
        }
    }
}

/// Widget style selection for widget configuration
enum StyleOption: String, AppEnum {
    case runeFirst
    case translationFirst

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Style"
    }

    static var caseDisplayRepresentations: [StyleOption: DisplayRepresentation] {
        [
            .runeFirst: "Rune First",
            .translationFirst: "Translation First",
        ]
    }

    var toWidgetStyle: WidgetStyle {
        switch self {
        case .runeFirst: .runeFirst
        case .translationFirst: .translationFirst
        }
    }

    init(from style: WidgetStyle) {
        switch style {
        case .runeFirst: self = .runeFirst
        case .translationFirst: self = .translationFirst
        }
    }
}

// MARK: - Widget Configuration Intent

/// Configuration intent for the Runic Quote widget
struct RunicQuoteConfigurationIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Configure Widget"
    static var description: IntentDescription {
        "Choose how your runic quote widget looks and behaves."
    }

    @Parameter(title: "Script", default: .elder)
    var script: ScriptOption

    @Parameter(title: "Mode", default: .daily)
    var mode: ModeOption

    @Parameter(title: "Style", default: .runeFirst)
    var style: StyleOption

    @Parameter(title: "Show Rune Text", default: true)
    var showRuneText: Bool
}
