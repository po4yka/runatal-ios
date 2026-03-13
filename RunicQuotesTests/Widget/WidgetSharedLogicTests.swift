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
        let deepLink = DeepLink.openQuote(script: .younger, mode: .random)
        let parsed = try #require(DeepLink.from(url: deepLink.url))

        #expect(parsed == .openQuote(script: .younger, mode: .random))
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
                showsRuneText: true,
            ),
            service: service,
        )

        #expect(timeline.entries.count == 2)
        #expect(timeline.entries[0].quote.textLatin == "Today")
        #expect(timeline.entries[1].quote.textLatin == "Tomorrow")
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
                showsRuneText: false,
            ),
            service: service,
        )

        #expect(timeline.entries[0].quote.textLatin == "First")
        #expect(timeline.entries[1].quote.textLatin == "Second")
        #expect(timeline.entries[1].date == now.addingTimeInterval(AppConstants.secondsPerHour))
        #expect(timeline.entries[0].showsDecorativeGlyphs == false)
        #expect(service.randomQuoteCallCount == 2)
        #expect(service.dailyQuoteRequests.isEmpty)
    }

    @Test
    func fallbackTimelineUsesPlaceholderAndHourlyRetry() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let generator = WidgetTimelineGenerator(now: { now })
        let timeline = generator.fallbackTimeline()

        #expect(timeline.entries.count == 1)
        #expect(timeline.entries[0].quote == .sample)
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

    func quoteOfTheDay(for script: RunicScript, date: Date) async throws -> QuoteData {
        self.dailyQuoteRequests.append(date)
        return self.dailyQuotes.removeFirst()
    }

    func randomQuote(for script: RunicScript) async throws -> QuoteData {
        self.randomQuoteCallCount += 1
        return self.randomQuotes.removeFirst()
    }
}
