//
//  WidgetSharedLogicTests.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import Foundation
@testable import RunicQuotes
import Testing

@Suite(.serialized, .tags(.widget))
struct DeepLinkTests {
    @Test
    func openQuoteRoundTripsThroughURL() throws {
        let id = UUID()
        let deepLink = DeepLink.openQuote(id: id, script: .younger, mode: .random, collection: .stoic)
        let parsed = try #require(DeepLink.from(url: deepLink.url))

        #expect(parsed == .openQuote(id: id, script: .younger, mode: .random, collection: .stoic))
    }

    @Test
    func invalidSchemeReturnsNil() throws {
        #expect(try DeepLink.from(url: #require(URL(string: "https://example.com"))) == nil)
    }

    @Test
    func settingsAndNextURLsUseConfiguredScheme() {
        #expect(DeepLink.openSettings.url.absoluteString == "runicquotes://settings")
        #expect(DeepLink.nextQuote.url.absoluteString == "runicquotes://next")
    }
}

@Suite(.serialized, .tags(.widget))
struct WidgetTimelineGeneratorTests {
    @Test
    func appDefaultsAndExplicitOverridesResolveIndependently() {
        var preferences = UserPreferencesSnapshot()
        preferences.selectedScript = .cirth
        preferences.selectedCollection = .stoic
        preferences.widgetMode = .random
        preferences.widgetStyle = .translationFirst
        preferences.widgetDecorativeGlyphsEnabled = false
        let defaults = WidgetDisplayConfiguration(collection: nil, script: nil, widgetMode: nil, widgetStyle: nil, showsDecorativeGlyphs: nil).resolved(using: preferences)
        #expect(defaults.script == .cirth)
        #expect(defaults.collection == .stoic)
        #expect(defaults.widgetMode == .random)
        #expect(defaults.widgetStyle == .translationFirst)
        #expect(!defaults.showsDecorativeGlyphs)
        let explicit = WidgetDisplayConfiguration(collection: .tolkien, script: .elder, widgetMode: .daily, widgetStyle: .runeFirst, showsDecorativeGlyphs: true).resolved(using: preferences)
        #expect(explicit.script == .elder)
        #expect(explicit.collection == .tolkien)
        #expect(explicit.widgetMode == .daily)
        #expect(explicit.widgetStyle == .runeFirst)
        #expect(explicit.showsDecorativeGlyphs)
    }

    @Test
    func dailyModeBuildsCurrentAndNextMidnightEntries() async throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(secondsFromGMT: 0))
        let now = Date(timeIntervalSince1970: 1_700_000_000)

        let service = TestWidgetTimelineService()
        service.preferences.selectedFont = .babelstone
        service.preferences.selectedTheme = .nordicDawn
        service.dailyQuotes = [
            QuoteData(textLatin: "Today", author: "Runatal", runicElder: "ᛏ", runicYounger: nil, runicCirth: nil),
            QuoteData(textLatin: "Tomorrow", author: "Runatal", runicElder: "ᛞ", runicYounger: nil, runicCirth: nil),
        ]

        let generator = WidgetTimelineGenerator(calendar: calendar, now: { now })
        let timeline = try await generator.generateTimeline(
            for: WidgetDisplayConfiguration(
                script: .elder,
                widgetMode: .daily,
                widgetStyle: .runeFirst,
                showsDecorativeGlyphs: true,
            ),
            service: service,
        )

        #expect(timeline.entries.count == 2)
        #expect(timeline.entries[0].quote?.textLatin == "Today")
        #expect(timeline.entries[1].quote?.textLatin == "Tomorrow")
        #expect(timeline.entries[0].font == .babelstone)
        #expect(timeline.entries[0].theme == .nordicDawn)
        #expect(timeline.entries[1].date == calendar.startOfDay(for: now.addingTimeInterval(AppConstants.secondsPerDay)))
        #expect(timeline.reloadPolicy == .atEnd)
        #expect(service.dailyQuoteRequests.count == 2)
        #expect(service.randomQuoteCallCount == 0)
    }

    @Test
    func randomModeUsesHourlyRefreshAndRandomQuotes() async throws {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let service = TestWidgetTimelineService()
        service.randomQuotes = [
            QuoteData(textLatin: "First", author: "Runatal", runicElder: nil, runicYounger: "ᚠ", runicCirth: nil),
            QuoteData(textLatin: "Second", author: "Runatal", runicElder: nil, runicYounger: "ᛋ", runicCirth: nil),
        ]

        let generator = WidgetTimelineGenerator(now: { now })
        let timeline = try await generator.generateTimeline(
            for: WidgetDisplayConfiguration(
                script: .younger,
                widgetMode: .random,
                widgetStyle: .translationFirst,
                showsDecorativeGlyphs: false,
            ),
            service: service,
        )

        #expect(timeline.entries[0].quote?.textLatin == "First")
        #expect(timeline.entries[1].quote?.textLatin == "Second")
        #expect(timeline.entries[1].date == now.addingTimeInterval(AppConstants.secondsPerHour))
        #expect(timeline.entries[0].showsDecorativeGlyphs == false)
        #expect(service.randomQuoteCallCount == 2)
        #expect(service.dailyQuoteRequests.isEmpty)
    }

    @Test
    func incompatibleGlobalFontUsesTheWidgetScriptsCompatibleFont() async throws {
        let service = TestWidgetTimelineService()
        service.preferences.selectedFont = .cirth
        let timeline = try await WidgetTimelineGenerator().generateTimeline(
            for: WidgetDisplayConfiguration(collection: .all, script: .elder, widgetMode: .daily, widgetStyle: .runeFirst, showsDecorativeGlyphs: nil),
            service: service,
        )
        #expect(timeline.entries.allSatisfy { $0.font == .noto && $0.font.isCompatible(with: $0.script) })
    }

    @Test
    func dailyRefreshUsesNextLocalMidnightAcrossShortAndLongDSTDays() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "America/New_York"))
        let generator = WidgetTimelineGenerator(calendar: calendar)
        for (month, day, hours) in [(3, 8, 23), (11, 1, 25)] {
            let midnight = try #require(calendar.date(from: DateComponents(year: 2026, month: month, day: day)))
            let next = generator.nextUpdateDate(after: midnight, mode: .daily)
            #expect(next > midnight)
            #expect(next.timeIntervalSince(midnight) == Double(hours) * 3600)
            #expect(calendar.component(.hour, from: next) == 0)
            #expect(calendar.component(.day, from: next) == day + 1)
        }
    }

    @Test
    func fallbackTimelineShowsUnavailableStateAndHourlyRetry() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let generator = WidgetTimelineGenerator(now: { now })
        let timeline = generator.fallbackTimeline()

        #expect(timeline.entries.count == 1)
        #expect(timeline.entries[0].quote == nil && timeline.entries[0].status == .unavailable)
        #expect(timeline.entries[0].widgetMode == .daily)

        if case .after(let retryDate) = timeline.reloadPolicy {
            #expect(retryDate == now.addingTimeInterval(AppConstants.secondsPerHour))
        } else {
            #expect(Bool(false))
        }
    }
}

private final class TestWidgetTimelineService: WidgetTimelineServicing, @unchecked Sendable {
    var preferences = UserPreferencesSnapshot()
    var dailyQuotes: [QuoteData] = [.sample, .sample]
    var randomQuotes: [QuoteData] = [.sample, .sample]

    private(set) var dailyQuoteRequests: [Date] = []
    private(set) var randomQuoteCallCount = 0

    func loadPreferences() throws -> UserPreferencesSnapshot {
        self.preferences
    }

    func quoteOfTheDay(for script: RunicScript, collection: QuoteCollection, date: Date) async throws -> QuoteData {
        self.dailyQuoteRequests.append(date)
        return self.dailyQuotes.removeFirst()
    }

    func randomQuote(for script: RunicScript, collection: QuoteCollection) async throws -> QuoteData {
        self.randomQuoteCallCount += 1
        return self.randomQuotes.removeFirst()
    }
}
