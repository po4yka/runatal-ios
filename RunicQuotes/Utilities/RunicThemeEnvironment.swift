//
//  RunicThemeEnvironment.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import SwiftUI

extension EnvironmentValues {
    @Entry var runicTheme: AppTheme = .obsidian
}

extension AppTheme {
    static func fromStorage(_ rawValue: String) -> AppTheme {
        AppTheme(rawValue: rawValue) ?? .obsidian
    }
}
