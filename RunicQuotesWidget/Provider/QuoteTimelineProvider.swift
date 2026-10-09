//
//  QuoteTimelineProvider.swift
//  RunicQuotes
//
//  Created by Claude on 09.10.25.
//

import os
import SwiftUI
@preconcurrency import WidgetKit

/// Timeline provider for the runic quotes widget with AppIntent configuration
struct QuoteTimelineProvider: AppIntentTimelineProvider {
    private static let logger = Logger(subsystem: AppConstants.loggingSubsystem, category: "Widget")
    private let makeTimelineService: @Sendable () throws -> any WidgetTimelineServicing
    private let generator: WidgetTimelineGenerator

    init(
        makeTimelineService: @escaping @Sendable () throws -> any WidgetTimelineServicing = Self.bootstrapTimelineService,
        generator: WidgetTimelineGenerator = WidgetTimelineGenerator(),
    ) {
        self.makeTimelineService = makeTimelineService
        self.generator = generator
    }

    // MARK: - AppIntentTimelineProvider Methods

    /// Provide a placeholder entry for widget gallery
    func placeholder(in context: Context) -> RunicQuoteEntry {
        RunicQuoteEntry.placeholder()
    }

    /// Provide a snapshot entry for widget preview
    func snapshot(for configuration: RunicQuoteConfigurationIntent, in context: Context) async -> RunicQuoteEntry {
        if context.isPreview {
            return RunicQuoteEntry.placeholder()
        }
        return await self.timeline(for: configuration, in: context).entries.first
            ?? RunicQuoteEntry(snapshot: self.generator.fallbackTimeline().entries[0])
    }

    /// Provide timeline entries for the widget
    func timeline(for configuration: RunicQuoteConfigurationIntent, in context: Context) async -> Timeline<RunicQuoteEntry> {
        let displayConfiguration = WidgetDisplayConfiguration(
            collection: configuration.collection.value,
            script: configuration.script.toRunicScript,
            widgetMode: configuration.mode.toWidgetMode,
            widgetStyle: configuration.style.toWidgetStyle,
            showsDecorativeGlyphs: configuration.decorativeGlyphs.value,
        )

        do {
            let service = try makeTimelineService()
            let timelineData = try await generator.generateTimeline(
                for: displayConfiguration,
                service: service,
            )
            return Timeline(
                entries: timelineData.entries.map(RunicQuoteEntry.init(snapshot:)),
                policy: self.timelinePolicy(for: timelineData.reloadPolicy),
            )
        } catch {
            Self.logger.error("Widget timeline error: \(error.localizedDescription)")
            let status: WidgetEntryStatus = if let quoteError = error as? QuoteRepositoryError, case .noQuotesAvailable = quoteError {
                .emptyLibrary
            } else {
                .unavailable
            }
            let timelineData = self.generator.fallbackTimeline(status: status)
            return Timeline(
                entries: timelineData.entries.map(RunicQuoteEntry.init(snapshot:)),
                policy: self.timelinePolicy(for: timelineData.reloadPolicy),
            )
        }
    }

    // MARK: - Private Methods

    private func timelinePolicy(for policy: WidgetTimelineReloadPolicy) -> TimelineReloadPolicy {
        switch policy {
        case .atEnd:
            .atEnd
        case .after(let date):
            .after(date)
        }
    }

    private static func bootstrapTimelineService() throws -> any WidgetTimelineServicing {
        do {
            registerProviderFactories()
            let rootComponent = try WidgetRootComponent(modelContainer: ModelContainerHelper.createSharedContainer())
            return rootComponent.timelineService
        } catch {
            self.logger.error("Failed to bootstrap widget root component: \(error.localizedDescription)")
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
            "No quotes available in the database"
        case .containerNotFound:
            "Could not access shared container"
        }
    }
}
