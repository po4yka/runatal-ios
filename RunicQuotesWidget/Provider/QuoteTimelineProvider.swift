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
    private let makeTimelineService: @Sendable () throws -> any WidgetTimelineServicing
    private let generator: WidgetTimelineGenerator

    init(
        makeTimelineService: @escaping @Sendable () throws -> any WidgetTimelineServicing = Self.bootstrapTimelineService,
        generator: WidgetTimelineGenerator = WidgetTimelineGenerator()
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
        RunicQuoteEntry.placeholder()
    }

    /// Provide timeline entries for the widget
    func timeline(for configuration: RunicQuoteConfigurationIntent, in context: Context) async -> Timeline<RunicQuoteEntry> {
        let displayConfiguration = WidgetDisplayConfiguration(
            script: configuration.script.toRunicScript,
            widgetMode: configuration.mode.toWidgetMode,
            widgetStyle: configuration.style.toWidgetStyle,
            showsRuneText: configuration.showRuneText
        )

        do {
            let service = try makeTimelineService()
            let timelineData = try await generator.generateTimeline(
                for: displayConfiguration,
                service: service
            )
            return Timeline(
                entries: timelineData.entries.map(RunicQuoteEntry.init(snapshot:)),
                policy: timelinePolicy(for: timelineData.reloadPolicy)
            )
        } catch {
            Self.logger.error("Widget timeline error: \(error.localizedDescription)")
            let timelineData = generator.fallbackTimeline()
            return Timeline(
                entries: timelineData.entries.map(RunicQuoteEntry.init(snapshot:)),
                policy: timelinePolicy(for: timelineData.reloadPolicy)
            )
        }
    }

    // MARK: - Private Methods

    private func timelinePolicy(for policy: WidgetTimelineReloadPolicy) -> TimelineReloadPolicy {
        switch policy {
        case .atEnd:
            return .atEnd
        case .after(let date):
            return .after(date)
        }
    }

    private static func bootstrapTimelineService() throws -> any WidgetTimelineServicing {
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
