//
//  UserPreferencesRepository+Environment.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import SwiftUI

enum PreviewUserPreferencesRepository {
    static let shared: any UserPreferencesRepository = InMemoryUserPreferencesRepository()
}

extension EnvironmentValues {
    @Entry var userPreferencesRepository: any UserPreferencesRepository = PreviewUserPreferencesRepository.shared
}

private final class InMemoryUserPreferencesRepository: UserPreferencesRepository, @unchecked Sendable {
    private var snapshotValue = UserPreferencesSnapshot()

    func snapshot() throws -> UserPreferencesSnapshot {
        self.snapshotValue
    }

    func save(_ snapshot: UserPreferencesSnapshot) throws {
        self.snapshotValue = snapshot
    }
}
