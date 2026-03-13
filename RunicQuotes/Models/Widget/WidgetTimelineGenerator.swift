//
//  WidgetTimelineGenerator.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import Foundation

struct WidgetDisplayConfiguration: Equatable {
    let script: RunicScript
    let widgetMode: WidgetMode
    let widgetStyle: WidgetStyle
    let showsRuneText: Bool
}

struct WidgetTimelineEntryData: Equatable {
    let date: Date
    let quote: QuoteData
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
    func quoteOfTheDay(for script: RunicScript, date: Date) async throws -> QuoteData
    func randomQuote(for script: RunicScript) async throws -> QuoteData
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
        let currentQuote = try await resolveQuote(
            service: service,
            mode: configuration.widgetMode,
            script: configuration.script,
            date: currentDate,
        )

        let nextUpdate = self.nextUpdateDate(after: currentDate, mode: configuration.widgetMode)
        let nextQuote = try await resolveQuote(
            service: service,
            mode: configuration.widgetMode,
            script: configuration.script,
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

    func fallbackTimeline(at date: Date? = nil) -> WidgetTimelineData {
        let currentDate = date ?? self.now()
        return WidgetTimelineData(
            entries: [
                WidgetTimelineEntryData(
                    date: currentDate,
                    quote: .sample,
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
            self.calendar.startOfDay(for: date.addingTimeInterval(AppConstants.secondsPerDay))
        case .random:
            date.addingTimeInterval(AppConstants.secondsPerHour)
        }
    }

    private func resolveQuote(
        service: any WidgetTimelineServicing,
        mode: WidgetMode,
        script: RunicScript,
        date: Date,
    ) async throws -> QuoteData {
        switch mode {
        case .daily:
            try await service.quoteOfTheDay(for: script, date: date)
        case .random:
            try await service.randomQuote(for: script)
        }
    }

    private func makeEntry(
        date: Date,
        quote: QuoteData,
        preferences: UserPreferencesSnapshot,
        configuration: WidgetDisplayConfiguration,
    ) -> WidgetTimelineEntryData {
        WidgetTimelineEntryData(
            date: date,
            quote: quote,
            script: configuration.script,
            font: preferences.selectedFont,
            theme: preferences.selectedTheme,
            widgetMode: configuration.widgetMode,
            widgetStyle: configuration.widgetStyle,
            showsDecorativeGlyphs: configuration.showsRuneText,
        )
    }
}
