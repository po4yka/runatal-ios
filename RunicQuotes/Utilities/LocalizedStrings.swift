//
//  LocalizedStrings.swift
//  RunicQuotes
//
//  Created by Claude on 2025-11-15.
//

import Foundation

/// Centralized localized strings for the app
enum LocalizedStrings {
    // MARK: - Quote View

    static let quoteTabTitle = NSLocalizedString(
        "quote.tab.title",
        value: "Quote",
        comment: "Tab title for Quote view"
    )

    static let loadingQuote = NSLocalizedString(
        "quote.loading",
        value: "Loading quote...",
        comment: "Loading message while fetching quote"
    )

    static let errorTitle = NSLocalizedString(
        "quote.error.title",
        value: "Error",
        comment: "Error title"
    )

    static let tryAgain = NSLocalizedString(
        "quote.error.tryAgain",
        value: "Try Again",
        comment: "Button to retry loading quote"
    )

    static let nextQuote = NSLocalizedString(
        "quote.action.next",
        value: "Next Quote",
        comment: "Button to load next quote"
    )

    static let shuffle = NSLocalizedString(
        "quote.action.shuffle",
        value: "Shuffle",
        comment: "Button to shuffle quotes"
    )

    // MARK: - Settings View

    static let settingsTabTitle = NSLocalizedString(
        "settings.tab.title",
        value: "Settings",
        comment: "Tab title for Settings view"
    )

    static let settingsTitle = NSLocalizedString(
        "settings.title",
        value: "Settings",
        comment: "Settings screen title"
    )

    static let settingsSubtitle = NSLocalizedString(
        "settings.subtitle",
        value: "Customize your runic experience",
        comment: "Settings screen subtitle"
    )

    // MARK: - Settings: Script Section

    static let scriptSectionTitle = NSLocalizedString(
        "settings.script.title",
        value: "Runic Script",
        comment: "Script section title"
    )

    // MARK: - Settings: Font Section

    static let fontSectionTitle = NSLocalizedString(
        "settings.font.title",
        value: "Font Style",
        comment: "Font section title"
    )

    static let fontSectionDescription = NSLocalizedString(
        "settings.font.description",
        value: "Choose your preferred runic font",
        comment: "Font section description"
    )

    // MARK: - Settings: Widget Section

    static let widgetSectionTitle = NSLocalizedString(
        "settings.widget.title",
        value: "Widget Settings",
        comment: "Widget section title"
    )

    static let widgetSectionDescription = NSLocalizedString(
        "settings.widget.description",
        value: "How should the widget display quotes?",
        comment: "Widget section description"
    )

    // MARK: - Settings: About Section

    static let aboutSectionTitle = NSLocalizedString(
        "settings.about.title",
        value: "About",
        comment: "About section title"
    )

    static let aboutApp = NSLocalizedString(
        "settings.about.app",
        value: "App",
        comment: "App label in about section"
    )

    static let aboutVersion = NSLocalizedString(
        "settings.about.version",
        value: "Version",
        comment: "Version label in about section"
    )

    static let aboutScripts = NSLocalizedString(
        "settings.about.scripts",
        value: "Scripts",
        comment: "Scripts label in about section"
    )

    static let aboutFonts = NSLocalizedString(
        "settings.about.fonts",
        value: "Fonts",
        comment: "Fonts label in about section"
    )

    static let aboutTagline = NSLocalizedString(
        "settings.about.tagline",
        value: "Bringing ancient wisdom to modern devices",
        comment: "App tagline in about section"
    )

    // MARK: - Widget Mode

    static let widgetModeDaily = NSLocalizedString(
        "widget.mode.daily",
        value: "Daily Quote",
        comment: "Daily quote widget mode name"
    )

    static let widgetModeDailyDescription = NSLocalizedString(
        "widget.mode.daily.description",
        value: "Same quote all day, changes at midnight",
        comment: "Daily quote widget mode description"
    )

    static let widgetModeRandom = NSLocalizedString(
        "widget.mode.random",
        value: "Random Quote",
        comment: "Random quote widget mode name"
    )

    static let widgetModeRandomDescription = NSLocalizedString(
        "widget.mode.random.description",
        value: "New quote every hour",
        comment: "Random quote widget mode description"
    )

    // MARK: - Runic Scripts

    static let elderFuthark = NSLocalizedString(
        "script.elderFuthark",
        value: "Elder Futhark",
        comment: "Elder Futhark script name"
    )

    static let elderFutharkDescription = NSLocalizedString(
        "script.elderFuthark.description",
        value: "The oldest runic alphabet (2nd-8th century)",
        comment: "Elder Futhark script description"
    )

    static let youngerFuthark = NSLocalizedString(
        "script.youngerFuthark",
        value: "Younger Futhark",
        comment: "Younger Futhark script name"
    )

    static let youngerFutharkDescription = NSLocalizedString(
        "script.youngerFuthark.description",
        value: "Viking Age runes (9th-11th century)",
        comment: "Younger Futhark script description"
    )

    static let cirth = NSLocalizedString(
        "script.cirth",
        value: "Cirth (Angerthas)",
        comment: "Cirth script name"
    )

    static let cirthDescription = NSLocalizedString(
        "script.cirth.description",
        value: "Tolkien's runic alphabet for Middle-earth",
        comment: "Cirth script description"
    )

    // MARK: - Runic Fonts

    static let notoRunic = NSLocalizedString(
        "font.notoRunic",
        value: "Noto Sans Runic",
        comment: "Noto Sans Runic font name"
    )

    static let babelStone = NSLocalizedString(
        "font.babelStone",
        value: "BabelStone Runic",
        comment: "BabelStone Runic font name"
    )

    static let cirthFont = NSLocalizedString(
        "font.cirth",
        value: "Cirth Angerthas",
        comment: "Cirth Angerthas font name"
    )

    // MARK: - Accessibility

    static let accessibilityQuoteCard = NSLocalizedString(
        "accessibility.quoteCard",
        value: "Quote card",
        comment: "Accessibility label for quote card"
    )

    static let accessibilityRunicText = NSLocalizedString(
        "accessibility.runicText",
        value: "Runic text",
        comment: "Accessibility label for runic text"
    )

    static let accessibilityAuthor = NSLocalizedString(
        "accessibility.author",
        value: "Author",
        comment: "Accessibility label for author"
    )

    static let accessibilityNextQuoteHint = NSLocalizedString(
        "accessibility.nextQuote.hint",
        value: "Double tap to load the next quote",
        comment: "Accessibility hint for next quote button"
    )

    static let accessibilityShuffleHint = NSLocalizedString(
        "accessibility.shuffle.hint",
        value: "Double tap to load a random quote",
        comment: "Accessibility hint for shuffle button"
    )
}
