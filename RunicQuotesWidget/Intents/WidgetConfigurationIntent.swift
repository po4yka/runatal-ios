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
    case appDefault
    case elder
    case younger
    case cirth

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Script"
    }

    static var caseDisplayRepresentations: [ScriptOption: DisplayRepresentation] {
        [
            .appDefault: "App Settings",
            .elder: "Elder Futhark",
            .younger: "Younger Futhark",
            .cirth: "Cirth",
        ]
    }

    var toRunicScript: RunicScript? {
        switch self {
        case .appDefault: nil
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
    case appDefault
    case daily
    case random

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Mode"
    }

    static var caseDisplayRepresentations: [ModeOption: DisplayRepresentation] {
        [
            .appDefault: "App Settings",
            .daily: "Daily Quote",
            .random: "Random Quote",
        ]
    }

    var toWidgetMode: WidgetMode? {
        switch self {
        case .appDefault: nil
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
    case appDefault
    case runeFirst
    case translationFirst

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Style"
    }

    static var caseDisplayRepresentations: [StyleOption: DisplayRepresentation] {
        [
            .appDefault: "App Settings",
            .runeFirst: "Rune First",
            .translationFirst: "Translation First",
        ]
    }

    var toWidgetStyle: WidgetStyle? {
        switch self {
        case .appDefault: nil
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

enum DecorationOption: String, AppEnum {
    case appDefault
    case enabled
    case disabled

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Decorative Glyphs"
    static let caseDisplayRepresentations: [DecorationOption: DisplayRepresentation] = [
        .appDefault: "App Settings", .enabled: "Enabled", .disabled: "Disabled",
    ]
    var value: Bool? {
        switch self {
        case .appDefault: nil
        case .enabled: true
        case .disabled: false
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

    @Parameter(title: "Collection", default: .appDefault)
    var collection: CollectionOption

    @Parameter(title: "Script", default: .appDefault)
    var script: ScriptOption

    @Parameter(title: "Mode", default: .appDefault)
    var mode: ModeOption

    @Parameter(title: "Style", default: .appDefault)
    var style: StyleOption

    @Parameter(title: "Decorative Glyphs", default: .appDefault)
    var decorativeGlyphs: DecorationOption
}

enum CollectionOption: String, AppEnum {
    case appDefault
    case all
    case motivation
    case stoic
    case tolkien

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Collection"
    static let caseDisplayRepresentations: [CollectionOption: DisplayRepresentation] = [
        .appDefault: "App default", .all: "All", .motivation: "Motivation", .stoic: "Stoic", .tolkien: "Tolkien",
    ]
    var value: QuoteCollection? {
        switch self {
        case .appDefault: nil
        case .all: .all
        case .motivation: .motivation
        case .stoic: .stoic
        case .tolkien: .tolkien
        }
    }
}
