//
//  TranslationBackfillState.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import Foundation
import SwiftData

/// Singleton record that tracks translation cache backfill progress.
@Model
final class TranslationBackfillState {
    @Attribute(.unique) var key: String
    var engineVersion: String
    var datasetVersion: String
    var processedCount: Int
    var startedAt: Date?
    var updatedAt: Date
    var completedAt: Date?
    var isCompleted: Bool

    init(
        key: String = TranslationBackfillState.singletonKey,
        engineVersion: String = "",
        datasetVersion: String = "",
        processedCount: Int = 0,
        startedAt: Date? = nil,
        updatedAt: Date = Date(),
        completedAt: Date? = nil,
        isCompleted: Bool = false,
    ) {
        self.key = key
        self.engineVersion = engineVersion
        self.datasetVersion = datasetVersion
        self.processedCount = processedCount
        self.startedAt = startedAt
        self.updatedAt = updatedAt
        self.completedAt = completedAt
        self.isCompleted = isCompleted
    }

    static let singletonKey = "translation-backfill-state"
}
