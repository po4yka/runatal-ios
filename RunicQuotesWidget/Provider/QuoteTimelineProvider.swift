//
//  QuoteTimelineProvider.swift
//  RunicQuotesWidget
//
//  Created by Claude on 2025-11-15.
//

@preconcurrency import WidgetKit
import SwiftUI
import SwiftData
import os

/// Timeline provider for the runic quotes widget with AppIntent configuration
struct QuoteTimelineProvider: AppIntentTimelineProvider {
    private static let logger = Logger(subsystem: AppConstants.loggingSubsystem, category: "Widget")

    // MARK: - AppIntentTimelineProvider Methods

    /// Provide a placeholder entry for widget gallery
    func placeholder(in context: Context) -> RunicQuoteEntry {
        RunicQuoteEntry.placeholder()
    }

    /// Provide a snapshot entry for widget preview
    func snapshot(for configuration: RunicQuoteConfigurationIntent, in context: Context) async -> RunicQuoteEntry {
        RunicQuoteEntry.placeholder()
    }

    /// Provide timeline entries for the widget
    func timeline(for configuration: RunicQuoteConfigurationIntent, in context: Context) async -> Timeline<RunicQuoteEntry> {
        do {
            let entries = try await generateEntries(for: configuration)
            return Timeline(entries: entries, policy: .atEnd)
        } catch {
            Self.logger.error("Widget timeline error: \(error.localizedDescription)")
            let entry = RunicQuoteEntry.placeholder()
            return Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(AppConstants.secondsPerHour)))
        }
    }

    // MARK: - Private Methods

    /// Generate timeline entries using intent configuration
    private func generateEntries(for configuration: RunicQuoteConfigurationIntent) async throws -> [RunicQuoteEntry] {
        let currentDate = Date()

        // Use intent values for per-widget configuration
        let script = configuration.script.toRunicScript
        let widgetMode = configuration.mode.toWidgetMode
        let widgetStyle = configuration.style.toWidgetStyle
        let showRuneText = configuration.showRuneText

        // Load remaining preferences from shared container (font, theme)
        let preferences = try await loadPreferences()

        // Get quote based on widget mode
        let quote: QuoteData
        if widgetMode == .daily {
            quote = try await getQuoteOfTheDay(for: script)
        } else {
            quote = try await getRandomQuote(for: script)
        }

        // Create entry for now
        let entry = RunicQuoteEntry(
            date: currentDate,
            quote: quote,
            script: script,
            font: preferences.selectedFont,
            theme: preferences.selectedTheme,
            widgetMode: widgetMode,
            widgetStyle: widgetStyle,
            showsDecorativeGlyphs: showRuneText
        )

        // For daily mode, update at midnight
        // For random mode, update every hour
        let nextUpdate: Date
        if widgetMode == .daily {
            nextUpdate = Calendar.current.startOfDay(for: currentDate.addingTimeInterval(AppConstants.secondsPerDay))
        } else {
            nextUpdate = currentDate.addingTimeInterval(AppConstants.secondsPerHour)
        }

        // Create entry for next update
        let nextQuote: QuoteData
        if widgetMode == .daily {
            nextQuote = try await getQuoteOfTheDay(for: script, date: nextUpdate)
        } else {
            nextQuote = try await getRandomQuote(for: script)
        }

        let nextEntry = RunicQuoteEntry(
            date: nextUpdate,
            quote: nextQuote,
            script: script,
            font: preferences.selectedFont,
            theme: preferences.selectedTheme,
            widgetMode: widgetMode,
            widgetStyle: widgetStyle,
            showsDecorativeGlyphs: showRuneText
        )

        return [entry, nextEntry]
    }

    /// Load user preferences from shared container
    private func loadPreferences() async throws -> UserPreferencesData {
        // Access SwiftData through shared container
        let container = try createSharedModelContainer()
        let context = ModelContext(container)

        let preferences = try UserPreferences.getOrCreate(in: context)

        return UserPreferencesData(
            selectedScript: preferences.selectedScript,
            selectedFont: preferences.selectedFont,
            selectedTheme: preferences.selectedTheme,
            widgetMode: preferences.widgetMode,
            widgetStyle: preferences.widgetStyle,
            widgetDecorativeGlyphsEnabled: preferences.widgetDecorativeGlyphsEnabled
        )
    }

    /// Get quote of the day
    private func getQuoteOfTheDay(for script: RunicScript, date: Date = Date()) async throws -> QuoteData {
        let container = try createSharedModelContainer()
        let context = ModelContext(container)
        let repository = SwiftDataQuoteRepository(modelContext: context)
        let provider = QuoteProvider(repository: repository)
        try await provider.seedIfNeeded()

        let allQuotes = try await provider.allQuotes()
        guard !allQuotes.isEmpty else {
            throw WidgetError.noQuotesAvailable
        }

        let index = AppConstants.dailyQuoteIndex(for: date, totalQuotes: allQuotes.count)
        let quote = allQuotes[index]

        return QuoteData(from: quote)
    }

    /// Get random quote
    private func getRandomQuote(for script: RunicScript) async throws -> QuoteData {
        let container = try createSharedModelContainer()
        let context = ModelContext(container)
        let repository = SwiftDataQuoteRepository(modelContext: context)
        let provider = QuoteProvider(repository: repository)
        try await provider.seedIfNeeded()

        let quote = try await provider.randomQuote(for: script)
        return QuoteData(from: quote)
    }

    /// Create shared model container for App Group access
    private func createSharedModelContainer() throws -> ModelContainer {
        try ModelContainerHelper.createSharedContainer()
    }
}

// MARK: - Supporting Types

/// User preferences data (non-SwiftData)
struct UserPreferencesData: Sendable {
    let selectedScript: RunicScript
    let selectedFont: RunicFont
    let selectedTheme: AppTheme
    let widgetMode: WidgetMode
    let widgetStyle: WidgetStyle
    let widgetDecorativeGlyphsEnabled: Bool
}

/// Widget-specific errors
enum WidgetError: LocalizedError {
    case noQuotesAvailable
    case containerNotFound

    var errorDescription: String? {
        switch self {
        case .noQuotesAvailable:
            return "No quotes available in the database"
        case .containerNotFound:
            return "Could not access shared container"
        }
    }
}
