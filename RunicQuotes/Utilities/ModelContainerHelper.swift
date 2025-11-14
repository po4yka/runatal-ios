//
//  ModelContainerHelper.swift
//  RunicQuotes
//
//  Created by Claude on 2025-11-15.
//

import Foundation
import SwiftData
import os

/// Helper for creating ModelContainers with proper error handling
enum ModelContainerHelper {
    private static let logger = Logger(subsystem: AppConstants.loggingSubsystem, category: "ModelContainer")

    /// Creates a placeholder in-memory ModelContainer for view initialization
    ///
    /// This is used as a temporary container until the environment's context is available.
    /// Primarily used in SwiftUI previews and test setup.
    ///
    /// - Returns: An in-memory ModelContainer
    /// - Warning: This method uses `fatalError` if container creation fails, which should only happen
    ///   if the SwiftData schema is invalid. This is intentional for preview/test code where
    ///   proceeding without a valid container would be meaningless.
    static func createPlaceholderContainer() -> ModelContainer {
        do {
            let schema = Schema([
                Quote.self,
                UserPreferences.self
            ])

            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            // This should never happen with in-memory containers.
            // If it does, we have a critical schema configuration issue that must be fixed.
            // Since this is used for previews/tests, a fatalError is appropriate - there's
            // no point continuing if the basic data model is broken.
            logger.critical("Failed to create placeholder container. This indicates a schema configuration error: \(error.localizedDescription, privacy: .public)")
            fatalError("""
                Critical error: Unable to create in-memory ModelContainer.
                Schema configuration is invalid. Error: \(error.localizedDescription)
                This must be fixed before previews/tests can run.
                """
            )
        }
    }

    /// Creates the main app ModelContainer with App Group support
    static func createMainContainer() throws -> ModelContainer {
        let schema = Schema([
            Quote.self,
            UserPreferences.self
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            groupContainer: .identifier(AppConstants.appGroupIdentifier)
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            logger.error("Failed to create main container: \(error.localizedDescription)")
            throw ModelContainerError.failedToCreate(error)
        }
    }

    /// Creates a shared ModelContainer for widget access
    static func createSharedContainer() async throws -> ModelContainer {
        let schema = Schema([
            Quote.self,
            UserPreferences.self
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            groupContainer: .identifier(AppConstants.appGroupIdentifier)
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            logger.error("Widget failed to create shared container: \(error.localizedDescription)")
            throw ModelContainerError.failedToCreate(error)
        }
    }
}

/// Errors related to ModelContainer creation
enum ModelContainerError: LocalizedError {
    case failedToCreate(Error)
    case containerNotAvailable

    var errorDescription: String? {
        switch self {
        case .failedToCreate(let error):
            return "Failed to create database: \(error.localizedDescription)"
        case .containerNotAvailable:
            return "Database is not available"
        }
    }

    var recoverySuggestion: String? {
        "Try restarting the app. If the problem persists, you may need to reinstall the app."
    }
}
