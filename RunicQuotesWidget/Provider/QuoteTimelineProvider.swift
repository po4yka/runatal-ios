//
//  QuoteTimelineProvider.swift
//  RunicQuotesWidget
//
//  Created by Claude on 2025-11-15.
//

@preconcurrency import WidgetKit
import SwiftUI
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
        let timelineService = try makeTimelineService()

        // Use intent values for per-widget configuration
        let script = configuration.script.toRunicScript
        let widgetMode = configuration.mode.toWidgetMode
        let widgetStyle = configuration.style.toWidgetStyle
        let showRuneText = configuration.showRuneText

        // Load remaining preferences from shared container (font, theme)
        let preferences = try timelineService.loadPreferences()

        // Get quote based on widget mode
        let quote: QuoteData
        if widgetMode == .daily {
            quote = try await timelineService.quoteOfTheDay(for: script)
        } else {
            quote = try await timelineService.randomQuote(for: script)
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
            nextQuote = try await timelineService.quoteOfTheDay(for: script, date: nextUpdate)
        } else {
            nextQuote = try await timelineService.randomQuote(for: script)
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

    private func makeTimelineService() throws -> WidgetTimelineService {
        do {
            registerProviderFactories()
            let rootComponent = try WidgetRootComponent(modelContainer: ModelContainerHelper.createSharedContainer())
            return rootComponent.timelineService
        } catch {
            Self.logger.error("Failed to bootstrap widget root component: \(error.localizedDescription)")
            throw WidgetError.containerNotFound
        }
    }
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
