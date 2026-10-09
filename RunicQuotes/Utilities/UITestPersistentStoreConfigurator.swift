//
//  UITestPersistentStoreConfigurator.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import CoreData
import Foundation
import os

enum UITestPersistentStoreConfigurator {
    private static let logger = Logger(subsystem: AppConstants.loggingSubsystem, category: "UITestStore")

    private static let uiTestingKey = "UI_TESTING"
    private static let resetStoreKey = "UI_TEST_RESET_PERSISTENT_STORE"
    private static let installLegacyStoreKey = "UI_TEST_INSTALL_LEGACY_STORE"
    private static let storeFileName = "default.store"
    private static var legacyQuoteID: UUID {
        guard let id = UUID(uuidString: "7B5D7832-E0A4-4E76-91F1-D06F3559E3A5") else {
            fatalError("Legacy quote identifier must remain a valid UUID.")
        }
        return id
    }

    static let legacyArchivedQuoteID = UUID(uuid: (0x7B, 0x5D, 0x78, 0x32, 0xE0, 0xA4, 0x4E, 0x76, 0x91, 0xF1, 0xD0, 0x6F, 0x35, 0x59, 0xE3, 0xA6))

    static let legacyQuoteText = "Legacy store quote survives migration."

    static func prepareIfNeeded(processInfo: ProcessInfo = .processInfo) {
        let environment = processInfo.environment
        guard environment[self.uiTestingKey] == "1" else { return }

        do {
            let storeURL = try persistentStoreURL()
            let shouldResetStore = environment[resetStoreKey] == "1" || environment[self.installLegacyStoreKey] == "1"

            if shouldResetStore {
                try self.removePersistentStoreFiles(at: storeURL)
            }

            if environment[self.installLegacyStoreKey] == "1" {
                try self.installLegacyStore(at: storeURL, withLegacyPreferences: true)
            }
        } catch {
            self.logger.error("Failed to prepare UI test store: \(error.localizedDescription, privacy: .public)")
        }
    }

    static func persistentStoreURL(fileManager: FileManager = .default) throws -> URL {
        guard let groupContainer = fileManager.containerURL(
            forSecurityApplicationGroupIdentifier: AppConstants.appGroupIdentifier,
        ) else {
            throw UITestPersistentStoreConfiguratorError.missingAppGroupContainer
        }

        let applicationSupportURL = groupContainer
            .appending(path: "Library", directoryHint: .isDirectory)
            .appending(path: "Application Support", directoryHint: .isDirectory)

        try fileManager.createDirectory(
            at: applicationSupportURL,
            withIntermediateDirectories: true,
        )

        return applicationSupportURL.appending(path: self.storeFileName)
    }

    private static func removePersistentStoreFiles(
        at storeURL: URL,
        fileManager: FileManager = .default,
    ) throws {
        let relatedURLs = [
            storeURL,
            URL(fileURLWithPath: storeURL.path + "-shm"),
            URL(fileURLWithPath: storeURL.path + "-wal"),
        ]

        for url in relatedURLs where fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
    }

    static func installLegacyStore(at storeURL: URL, withLegacyPreferences: Bool = false) throws {
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: legacyModel(includePreferences: withLegacyPreferences))
        let options: [AnyHashable: Any] = [
            NSSQLitePragmasOption: ["journal_mode": "DELETE"],
        ]
        let store = try coordinator.addPersistentStore(
            type: .sqlite,
            configuration: nil,
            at: storeURL,
            options: options,
        )

        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator

        let quote = NSEntityDescription.insertNewObject(forEntityName: "Quote", into: context)
        quote.setValue(self.legacyQuoteID, forKey: "id")
        quote.setValue(self.legacyQuoteText, forKey: "textLatin")
        quote.setValue("Codex", forKey: "author")
        quote.setValue("Stoic", forKey: "collectionRaw")
        quote.setValue("ᛚᛖᚷᚨᚲᛁ", forKey: "runicElder")
        quote.setValue("ᛚᛁᚴᚨᛋᛁ", forKey: "runicYounger")
        quote.setValue("legacy", forKey: "runicCirth")
        quote.setValue(Date(timeIntervalSince1970: 1_700_000_000), forKey: "createdAt")
        quote.setValue(false, forKey: "isUserGenerated")
        quote.setValue(false, forKey: "isHidden")
        quote.setValue(false, forKey: "isDeleted")
        quote.setValue(nil, forKey: "deletedAt")

        if withLegacyPreferences {
            self.insertLegacyArchivedQuote(in: context)
            self.insertLegacyPreferences(in: context)
        }
        try context.save()
        try coordinator.remove(store)
    }

    private static func legacyModel(includePreferences: Bool) -> NSManagedObjectModel {
        let quote = NSEntityDescription()
        quote.name = "Quote"
        quote.managedObjectClassName = "NSManagedObject"
        quote.properties = [
            self.attribute(named: "id", type: .UUIDAttributeType, isOptional: false),
            self.attribute(named: "textLatin", type: .stringAttributeType, isOptional: false),
            self.attribute(named: "author", type: .stringAttributeType, isOptional: false),
            self.attribute(named: "source", type: .stringAttributeType, isOptional: true),
            self.attribute(named: "collectionRaw", type: .stringAttributeType, isOptional: true),
            self.attribute(named: "runicElder", type: .stringAttributeType, isOptional: true),
            self.attribute(named: "runicYounger", type: .stringAttributeType, isOptional: true),
            self.attribute(named: "runicCirth", type: .stringAttributeType, isOptional: true),
            self.attribute(named: "createdAt", type: .dateAttributeType, isOptional: false),
            self.attribute(named: "isUserGenerated", type: .booleanAttributeType, isOptional: false),
            self.attribute(named: "isHidden", type: .booleanAttributeType, isOptional: false),
            self.attribute(named: "isDeleted", type: .booleanAttributeType, isOptional: false),
            self.attribute(named: "deletedAt", type: .dateAttributeType, isOptional: true),
        ]
        quote.uniquenessConstraints = [["id"]]

        let model = NSManagedObjectModel()
        model.entities = includePreferences ? [quote, self.legacyPreferencesEntity()] : [quote]
        return model
    }

    private static func legacyPreferencesEntity() -> NSEntityDescription {
        let preferences = NSEntityDescription()
        preferences.name = "UserPreferences"
        preferences.managedObjectClassName = "NSManagedObject"
        preferences.properties = [
            self.attribute(named: "id", type: .UUIDAttributeType, isOptional: false),
            self.attribute(named: "selectedScriptRaw", type: .stringAttributeType, isOptional: false),
            self.attribute(named: "selectedFontRaw", type: .stringAttributeType, isOptional: false),
            self.attribute(named: "widgetModeRaw", type: .stringAttributeType, isOptional: false),
            self.attribute(named: "selectedCollectionRaw", type: .stringAttributeType, isOptional: true),
            self.attribute(named: "widgetStyleRaw", type: .stringAttributeType, isOptional: true),
            self.attribute(named: "widgetDecorativeGlyphsEnabledRaw", type: .booleanAttributeType, isOptional: true),
            self.attribute(named: "selectedThemeRaw", type: .stringAttributeType, isOptional: false),
            self.attribute(named: "lastUsedPresetRaw", type: .stringAttributeType, isOptional: true),
            self.attribute(named: "savedQuoteIDsRaw", type: .stringAttributeType, isOptional: true),
            self.attribute(named: "installedPackIDsRaw", type: .stringAttributeType, isOptional: true),
            self.attribute(named: "lastUpdated", type: .dateAttributeType, isOptional: false),
        ]
        preferences.uniquenessConstraints = [["id"]]
        return preferences
    }

    private static func insertLegacyArchivedQuote(in context: NSManagedObjectContext) {
        let quote = NSEntityDescription.insertNewObject(forEntityName: "Quote", into: context)
        quote.setValue(self.legacyArchivedQuoteID, forKey: "id")
        quote.setValue("Legacy trash remains archived.", forKey: "textLatin")
        quote.setValue("Codex", forKey: "author")
        quote.setValue("Stoic", forKey: "collectionRaw")
        quote.setValue("legacy-trash", forKey: "runicCirth")
        quote.setValue(Date(timeIntervalSince1970: 1_700_000_000), forKey: "createdAt")
        quote.setValue(false, forKey: "isUserGenerated")
        quote.setValue(false, forKey: "isHidden")
        quote.setValue(true, forKey: "isDeleted")
        quote.setValue(Date(timeIntervalSince1970: 1_700_000_000), forKey: "deletedAt")
    }

    private static func insertLegacyPreferences(in context: NSManagedObjectContext) {
        for (index, theme) in [AppTheme.obsidian, AppTheme.nordicDawn].enumerated() {
            let preferences = NSEntityDescription.insertNewObject(forEntityName: "UserPreferences", into: context)
            preferences.setValue(UUID(), forKey: "id")
            preferences.setValue(RunicScript.younger.rawValue, forKey: "selectedScriptRaw")
            preferences.setValue(RunicFont.babelstone.rawValue, forKey: "selectedFontRaw")
            preferences.setValue(WidgetMode.random.rawValue, forKey: "widgetModeRaw")
            preferences.setValue(QuoteCollection.stoic.rawValue, forKey: "selectedCollectionRaw")
            preferences.setValue(WidgetStyle.translationFirst.rawValue, forKey: "widgetStyleRaw")
            preferences.setValue(false, forKey: "widgetDecorativeGlyphsEnabledRaw")
            preferences.setValue(theme.rawValue, forKey: "selectedThemeRaw")
            preferences.setValue(index == 0 ? self.legacyQuoteID.uuidString : self.legacyArchivedQuoteID.uuidString, forKey: "savedQuoteIDsRaw")
            preferences.setValue(index == 0 ? "havamal" : "meditations", forKey: "installedPackIDsRaw")
            preferences.setValue(Date(timeIntervalSince1970: 1_700_000_000 + Double(index)), forKey: "lastUpdated")
        }
    }

    private static func attribute(
        named name: String,
        type: NSAttributeType,
        isOptional: Bool,
    ) -> NSAttributeDescription {
        let attribute = NSAttributeDescription()
        attribute.name = name
        attribute.attributeType = type
        attribute.isOptional = isOptional
        return attribute
    }
}

enum UITestPersistentStoreConfiguratorError: LocalizedError {
    case missingAppGroupContainer

    var errorDescription: String? {
        switch self {
        case .missingAppGroupContainer:
            "App Group container is unavailable for UI test store setup."
        }
    }
}
