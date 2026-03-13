//
//  RunicThemeEnvironment.swift
//  RunicQuotes
//
//  Created by Codex on 2026-03-13.
//

import SwiftUI

private struct RunicThemeKey: EnvironmentKey {
    static let defaultValue: AppTheme = .obsidian
}

extension EnvironmentValues {
    var runicTheme: AppTheme {
        get { self[RunicThemeKey.self] }
        set { self[RunicThemeKey.self] = newValue }
    }
}

extension AppTheme {
    static func fromStorage(_ rawValue: String) -> AppTheme {
        AppTheme(rawValue: rawValue) ?? .obsidian
    }
}
