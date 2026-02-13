//
//  QuoteTimelineProvider.swift
//  RunicQuotesWidget
//
//  Created by Claude on 2025-11-15.
//

import WidgetKit
import SwiftUI
import SwiftData
import os

/// Timeline provider for the runic quotes widget
struct QuoteTimelineProvider: TimelineProvider {
    private static let logger = Logger(subsystem: AppConstants.loggingSubsystem, category: "Widget")

    // MARK: - TimelineProvider Methods

    /// Provide a placeholder entry for widget gallery
    func placeholder(in context: Context) -> RunicQuoteEntry {
        RunicQuoteEntry.placeholder()
    }

    /// Provide a snapshot entry for widget preview
    func getSnapshot(in context: Context, completion: @escaping (RunicQuoteEntry) -> Void) {
        let entry = RunicQuoteEntry.placeholder()
        completion(entry)
    }

    /// Provide timeline entries for the widget
    func getTimeline(in context: Context, completion: @escaping (Timeline<RunicQuoteEntry>) -> Void) {
        Task {
            do {
                let entries = try await generateEntries(for: context)
                let timeline = Timeline(entries: entries, policy: .atEnd)
                completion(timeline)
            } catch {
                Self.logger.error("Widget timeline error: \(error.localizedDescription)")
                // Fallback to placeholder
                let entry = RunicQuoteEntry.placeholder()
                let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(3600)))
                completion(timeline)
            }
        }
    }

    // MARK: - Private Methods

    /// Generate timeline entries
    private func generateEntries(for context: Context) async throws -> [RunicQuoteEntry] {
        let currentDate = Date()

        // Load user preferences
        let preferences = try await loadPreferences()

        // Get quote based on widget mode
        let quote: QuoteData
        if preferences.widgetMode == .daily {
            quote = try await getQuoteOfTheDay(for: preferences.selectedScript)
        } else {
            quote = try await getRandomQuote(for: preferences.selectedScript)
        }

        // Create entry for now
        let entry = RunicQuoteEntry(
            date: currentDate,
            quote: quote,
            script: preferences.selectedScript,
            font: preferences.selectedFont,
            theme: preferences.selectedTheme,
            widgetMode: preferences.widgetMode,
            widgetStyle: preferences.widgetStyle,
            showsDecorativeGlyphs: preferences.widgetDecorativeGlyphsEnabled
        )

        // For daily mode, update at midnight
        // For random mode, update every hour
        let nextUpdate: Date
        if preferences.widgetMode == .daily {
            nextUpdate = Calendar.current.startOfDay(for: currentDate.addingTimeInterval(86400)) // Next day at midnight
        } else {
            nextUpdate = currentDate.addingTimeInterval(3600) // 1 hour
        }

        // Create entry for next update
        let nextQuote: QuoteData
        if preferences.widgetMode == .daily {
            // For daily mode, calculate what the next day's quote will be
            nextQuote = try await getQuoteOfTheDay(for: preferences.selectedScript, date: nextUpdate)
        } else {
            nextQuote = try await getRandomQuote(for: preferences.selectedScript)
        }

        let nextEntry = RunicQuoteEntry(
            date: nextUpdate,
            quote: nextQuote,
            script: preferences.selectedScript,
            font: preferences.selectedFont,
            theme: preferences.selectedTheme,
            widgetMode: preferences.widgetMode,
            widgetStyle: preferences.widgetStyle,
            showsDecorativeGlyphs: preferences.widgetDecorativeGlyphsEnabled
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

        // Use the same deterministic algorithm as the app
        let calendar = Calendar.current
        let targetDay = calendar.startOfDay(for: date)
        let daysSinceEpoch = calendar.dateComponents([.day], from: Date(timeIntervalSince1970: 0), to: targetDay).day ?? 0

        let allQuotes = try await provider.allQuotes()
        guard !allQuotes.isEmpty else {
            throw WidgetError.noQuotesAvailable
        }

        let index = daysSinceEpoch % allQuotes.count
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
        let schema = Schema([
            Quote.self,
            UserPreferences.self
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            groupContainer: .identifier(AppConstants.appGroupIdentifier)
        )

        return try ModelContainer(for: schema, configurations: [modelConfiguration])
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
