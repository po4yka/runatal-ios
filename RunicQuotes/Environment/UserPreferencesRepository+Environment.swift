//
//  UserPreferencesRepository+Environment.swift
//  RunicQuotes
//
//  Created by Codex on 2026-03-13.
//

import SwiftUI

enum PreviewUserPreferencesRepository {
    static let shared: any UserPreferencesRepository = InMemoryUserPreferencesRepository()
}

private struct UserPreferencesRepositoryKey: EnvironmentKey {
    static let defaultValue: any UserPreferencesRepository = PreviewUserPreferencesRepository.shared
}

extension EnvironmentValues {
    var userPreferencesRepository: any UserPreferencesRepository {
        get { self[UserPreferencesRepositoryKey.self] }
        set { self[UserPreferencesRepositoryKey.self] = newValue }
    }
}

private final class InMemoryUserPreferencesRepository: UserPreferencesRepository, @unchecked Sendable {
    private var snapshotValue = UserPreferencesSnapshot()

    func snapshot() throws -> UserPreferencesSnapshot {
        snapshotValue
    }

    func save(_ snapshot: UserPreferencesSnapshot) throws {
        snapshotValue = snapshot
    }
}
