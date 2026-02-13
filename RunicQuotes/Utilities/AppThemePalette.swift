//
//  AppThemePalette.swift
//  RunicQuotes
//
//  Created by Claude on 2025-11-15.
//

import SwiftUI

/// Theme-driven visual tokens used by the app and widget.
struct AppThemePalette {
    let appBackgroundGradient: [Color]
    let widgetBackgroundGradient: [Color]
    let primaryText: Color
    let secondaryText: Color
    let tertiaryText: Color
    let divider: Color
    let accent: Color
    let ctaAccent: Color
    let footerBackground: Color
}

extension AppTheme {
    var palette: AppThemePalette {
        switch self {
        case .obsidian:
            return AppThemePalette(
                appBackgroundGradient: [
                    Color(red: 0.02, green: 0.03, blue: 0.07),
                    Color(red: 0.08, green: 0.11, blue: 0.18),
                    Color(red: 0.14, green: 0.16, blue: 0.26),
                    Color(red: 0.06, green: 0.09, blue: 0.15),
                    Color(red: 0.01, green: 0.02, blue: 0.05)
                ],
                widgetBackgroundGradient: [
                    Color(red: 0.03, green: 0.05, blue: 0.10),
                    Color(red: 0.10, green: 0.14, blue: 0.22),
                    Color(red: 0.03, green: 0.05, blue: 0.10)
                ],
                primaryText: .white,
                secondaryText: Color.white.opacity(0.86),
                tertiaryText: Color.white.opacity(0.70),
                divider: Color.white.opacity(0.30),
                accent: Color(red: 0.57, green: 0.80, blue: 0.98),
                ctaAccent: Color(red: 0.40, green: 0.58, blue: 0.75),
                footerBackground: Color.white.opacity(0.06)
            )
        case .parchment:
            return AppThemePalette(
                appBackgroundGradient: [
                    Color(red: 0.14, green: 0.09, blue: 0.05),
                    Color(red: 0.24, green: 0.15, blue: 0.09),
                    Color(red: 0.36, green: 0.24, blue: 0.15),
                    Color(red: 0.23, green: 0.14, blue: 0.09),
                    Color(red: 0.12, green: 0.07, blue: 0.04)
                ],
                widgetBackgroundGradient: [
                    Color(red: 0.18, green: 0.11, blue: 0.07),
                    Color(red: 0.31, green: 0.20, blue: 0.12),
                    Color(red: 0.18, green: 0.11, blue: 0.07)
                ],
                primaryText: Color(red: 0.97, green: 0.92, blue: 0.84),
                secondaryText: Color(red: 0.92, green: 0.84, blue: 0.73),
                tertiaryText: Color(red: 0.84, green: 0.74, blue: 0.61),
                divider: Color(red: 0.95, green: 0.88, blue: 0.75).opacity(0.35),
                accent: Color(red: 0.96, green: 0.74, blue: 0.45),
                ctaAccent: Color(red: 0.72, green: 0.55, blue: 0.38),
                footerBackground: Color(red: 0.63, green: 0.44, blue: 0.27).opacity(0.35)
            )
        case .nordicDawn:
            return AppThemePalette(
                appBackgroundGradient: [
                    Color(red: 0.03, green: 0.12, blue: 0.19),
                    Color(red: 0.08, green: 0.22, blue: 0.33),
                    Color(red: 0.16, green: 0.33, blue: 0.46),
                    Color(red: 0.10, green: 0.24, blue: 0.35),
                    Color(red: 0.04, green: 0.12, blue: 0.20)
                ],
                widgetBackgroundGradient: [
                    Color(red: 0.04, green: 0.15, blue: 0.24),
                    Color(red: 0.11, green: 0.28, blue: 0.41),
                    Color(red: 0.04, green: 0.15, blue: 0.24)
                ],
                primaryText: Color(red: 0.95, green: 0.98, blue: 1.00),
                secondaryText: Color(red: 0.86, green: 0.93, blue: 0.98),
                tertiaryText: Color(red: 0.72, green: 0.83, blue: 0.92),
                divider: Color(red: 0.82, green: 0.90, blue: 0.97).opacity(0.35),
                accent: Color(red: 0.58, green: 0.86, blue: 1.00),
                ctaAccent: Color(red: 0.42, green: 0.62, blue: 0.76),
                footerBackground: Color(red: 0.33, green: 0.53, blue: 0.66).opacity(0.25)
            )
        }
    }
}
