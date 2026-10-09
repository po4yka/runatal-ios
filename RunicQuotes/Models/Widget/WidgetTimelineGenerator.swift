//
//  WidgetTimelineGenerator.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import Foundation

struct WidgetDisplayConfiguration: Equatable {
    var collection: QuoteCollection?
    let script: RunicScript?
    let widgetMode: WidgetMode?
    let widgetStyle: WidgetStyle?
    let showsDecorativeGlyphs: Bool?

    func resolved(using preferences: UserPreferencesSnapshot) -> EffectiveWidgetConfiguration {
        EffectiveWidgetConfiguration(
            collection: self.collection ?? preferences.selectedCollection,
            script: self.script ?? preferences.selectedScript,
            widgetMode: self.widgetMode ?? preferences.widgetMode,
            widgetStyle: self.widgetStyle ?? preferences.widgetStyle,
            showsDecorativeGlyphs: self.showsDecorativeGlyphs ?? preferences.widgetDecorativeGlyphsEnabled,
        )
    }
}

struct EffectiveWidgetConfiguration: Equatable {
    let collection: QuoteCollection
    let script: RunicScript
    let widgetMode: WidgetMode
    let widgetStyle: WidgetStyle
    let showsDecorativeGlyphs: Bool
}

enum WidgetEntryStatus: String, Equatable, Sendable {
    case quote
    case preview
    case emptyLibrary
    case unavailable

    var isPresentingQuote: Bool {
        self == .quote || self == .preview
    }

    var title: String {
        switch self {
        case .quote, .preview: "Runatal"
        case .emptyLibrary: "No passages in this collection"
        case .unavailable: "Library temporarily unavailable"
        }
    }
}

struct WidgetTimelineEntryData: Equatable {
    var status: WidgetEntryStatus = .quote
    var collection: QuoteCollection = .all
    let date: Date
    let quote: QuoteData?
    let script: RunicScript
    let font: RunicFont
    let theme: AppTheme
    let widgetMode: WidgetMode
    let widgetStyle: WidgetStyle
    let showsDecorativeGlyphs: Bool
}

enum WidgetTimelineReloadPolicy: Equatable {
    case atEnd
    case after(Date)
}

struct WidgetTimelineData: Equatable {
    let entries: [WidgetTimelineEntryData]
    let reloadPolicy: WidgetTimelineReloadPolicy
}

protocol WidgetTimelineServicing: Sendable {
    func loadPreferences() throws -> UserPreferencesSnapshot
    func quoteOfTheDay(for script: RunicScript, collection: QuoteCollection, date: Date) async throws -> QuoteData
    func randomQuote(for script: RunicScript, collection: QuoteCollection) async throws -> QuoteData
}

struct WidgetTimelineGenerator {
    var calendar: Calendar
    private let now: @Sendable () -> Date

    init(
        calendar: Calendar = .current,
        now: @escaping @Sendable () -> Date = Date.init,
    ) {
        self.calendar = calendar
        self.now = now
    }

    func generateTimeline(
        for configuration: WidgetDisplayConfiguration,
        service: any WidgetTimelineServicing,
    ) async throws -> WidgetTimelineData {
        let currentDate = self.now()
        let preferences = try service.loadPreferences()
        let configuration = configuration.resolved(using: preferences)
        let currentQuote = try await resolveQuote(
            service: service,
            mode: configuration.widgetMode,
            script: configuration.script,
            collection: configuration.collection,
            date: currentDate,
        )

        let nextUpdate = self.nextUpdateDate(after: currentDate, mode: configuration.widgetMode)
        let nextQuote = try await resolveQuote(
            service: service,
            mode: configuration.widgetMode,
            script: configuration.script,
            collection: configuration.collection,
            date: nextUpdate,
        )

        return WidgetTimelineData(
            entries: [
                self.makeEntry(
                    date: currentDate,
                    quote: currentQuote,
                    preferences: preferences,
                    configuration: configuration,
                ),
                self.makeEntry(
                    date: nextUpdate,
                    quote: nextQuote,
                    preferences: preferences,
                    configuration: configuration,
                ),
            ],
            reloadPolicy: .atEnd,
        )
    }

    func fallbackTimeline(at date: Date? = nil, status: WidgetEntryStatus = .unavailable) -> WidgetTimelineData {
        let currentDate = date ?? self.now()
        return WidgetTimelineData(
            entries: [
                WidgetTimelineEntryData(
                    status: status,
                    date: currentDate,
                    quote: nil,
                    script: .elder,
                    font: .noto,
                    theme: .obsidian,
                    widgetMode: .daily,
                    widgetStyle: .runeFirst,
                    showsDecorativeGlyphs: true,
                ),
            ],
            reloadPolicy: .after(currentDate.addingTimeInterval(AppConstants.secondsPerHour)),
        )
    }

    func nextUpdateDate(after date: Date, mode: WidgetMode) -> Date {
        switch mode {
        case .daily:
            self.calendar.date(byAdding: .day, value: 1, to: self.calendar.startOfDay(for: date))
                ?? date.addingTimeInterval(AppConstants.secondsPerDay)
        case .random:
            date.addingTimeInterval(AppConstants.secondsPerHour)
        }
    }

    private func resolveQuote(
        service: any WidgetTimelineServicing,
        mode: WidgetMode,
        script: RunicScript,
        collection: QuoteCollection,
        date: Date,
    ) async throws -> QuoteData {
        switch mode {
        case .daily:
            try await service.quoteOfTheDay(for: script, collection: collection, date: date)
        case .random:
            try await service.randomQuote(for: script, collection: collection)
        }
    }

    private func makeEntry(
        date: Date,
        quote: QuoteData,
        preferences: UserPreferencesSnapshot,
        configuration: EffectiveWidgetConfiguration,
    ) -> WidgetTimelineEntryData {
        WidgetTimelineEntryData(
            collection: configuration.collection,
            date: date,
            quote: quote,
            script: configuration.script,
            font: preferences.selectedFont.isCompatible(with: configuration.script)
                ? preferences.selectedFont : RunicFontConfiguration.recommendedFont(for: configuration.script),
            theme: preferences.selectedTheme,
            widgetMode: configuration.widgetMode,
            widgetStyle: configuration.widgetStyle,
            showsDecorativeGlyphs: configuration.showsDecorativeGlyphs,
        )
    }
}
