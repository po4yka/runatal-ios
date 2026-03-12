//
//  AppThemePalette.swift
//  RunicQuotes
//
//  Created by Claude on 2025-11-15.
//

import SwiftUI

/// Theme-driven visual tokens used by the app and widget.
struct AppThemePalette {

    // MARK: - Legacy Tokens (3-theme system)

    let appBackgroundGradient: [Color]
    let widgetBackgroundGradient: [Color]
    let primaryText: Color
    let secondaryText: Color
    let tertiaryText: Color
    let divider: Color
    let accent: Color
    let ctaAccent: Color
    let footerBackground: Color

    // MARK: - Adaptive Tokens (dark/light system)

    let background: Color
    let groupedBG: Color
    let surface: Color
    let surfaceElevated: Color
    let accentSecondary: Color
    let textPrimary: Color
    let textSecondary: Color
    let textTertiary: Color
    let runeText: Color
    let success: Color
    let warning: Color
    let error: Color
    let separator: Color
}

// MARK: - Adaptive Palette Factory

extension AppThemePalette {

    /// Creates a palette with the new Scandinavian cold-slate design system tokens,
    /// adapting colors for the given color scheme. Fills legacy tokens from the
    /// corresponding adaptive values for consistency.
    static func adaptive(for colorScheme: ColorScheme) -> AppThemePalette {
        switch colorScheme {
        case .dark:
            return darkPalette
        case .light:
            return lightPalette
        @unknown default:
            return darkPalette
        }
    }

    // MARK: - Dark Palette

    private static let darkPalette = AppThemePalette(
        // Legacy tokens mapped from new dark system
        appBackgroundGradient: [
            Color(hex: 0x070A10),
            Color(hex: 0x0C1118),
            Color(hex: 0x141C28),
            Color(hex: 0x0C1118),
            Color(hex: 0x070A10)
        ],
        widgetBackgroundGradient: [
            Color(hex: 0x070A10),
            Color(hex: 0x141C28),
            Color(hex: 0x070A10)
        ],
        primaryText: Color(hex: 0xE6EEF8),
        secondaryText: Color(hex: 0x7C8DA6),
        tertiaryText: Color(hex: 0x4E5C72),
        divider: Color(hex: 0x1E2836),
        accent: Color(hex: 0x8C9AB0),
        ctaAccent: Color(hex: 0x7494AE),
        footerBackground: Color(hex: 0x141C28),
        // New adaptive tokens
        background: Color(hex: 0x070A10),
        groupedBG: Color(hex: 0x0C1118),
        surface: Color(hex: 0x141C28),
        surfaceElevated: Color(hex: 0x1A2434),
        accentSecondary: Color(hex: 0x7494AE),
        textPrimary: Color(hex: 0xE6EEF8),
        textSecondary: Color(hex: 0x7C8DA6),
        textTertiary: Color(hex: 0x4E5C72),
        runeText: Color(hex: 0xA8B8D0),
        success: Color(hex: 0x68A878),
        warning: Color(hex: 0x98926C),
        error: Color(hex: 0xBE5E5E),
        separator: Color(hex: 0x1E2836)
    )

    // MARK: - Light Palette

    private static let lightPalette = AppThemePalette(
        // Legacy tokens mapped from new light system
        appBackgroundGradient: [
            Color(hex: 0xF2F4F8),
            Color(hex: 0xEAECF1),
            Color(hex: 0xF2F4F8)
        ],
        widgetBackgroundGradient: [
            Color(hex: 0xF2F4F8),
            Color(hex: 0xEAECF1),
            Color(hex: 0xF2F4F8)
        ],
        primaryText: Color(hex: 0x0A0F17),
        secondaryText: Color(hex: 0x48566A),
        tertiaryText: Color(hex: 0x48566A).opacity(0.7),
        divider: Color(hex: 0x48566A).opacity(0.2),
        accent: Color(hex: 0x3B4B5E),
        ctaAccent: Color(hex: 0x4A6A82),
        footerBackground: Color(hex: 0xEAECF1),
        // New adaptive tokens
        background: Color(hex: 0xF2F4F8),
        groupedBG: Color(hex: 0xEAECF1),
        surface: .white,
        surfaceElevated: Color(hex: 0xFAFBFD),
        accentSecondary: Color(hex: 0x4A6A82),
        textPrimary: Color(hex: 0x0A0F17),
        textSecondary: Color(hex: 0x48566A),
        textTertiary: Color(hex: 0x48566A).opacity(0.7),
        runeText: Color(hex: 0x1A2434),
        success: Color(hex: 0x387850),
        warning: Color(hex: 0x98926C),
        error: Color(hex: 0x9E3636),
        separator: Color(hex: 0x48566A).opacity(0.2)
    )
}

// MARK: - Color Hex Initializer

extension Color {
    /// Creates a color from a hex integer (e.g., `0x070A10`).
    init(hex: UInt32) {
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue)
    }
}

// MARK: - Legacy Theme Palettes

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
                footerBackground: Color.white.opacity(0.06),
                background: Color(hex: 0x070A10),
                groupedBG: Color(hex: 0x0C1118),
                surface: Color(hex: 0x141C28),
                surfaceElevated: Color(hex: 0x1A2434),
                accentSecondary: Color(hex: 0x7494AE),
                textPrimary: .white,
                textSecondary: Color.white.opacity(0.86),
                textTertiary: Color.white.opacity(0.70),
                runeText: Color(hex: 0xA8B8D0),
                success: Color(hex: 0x68A878),
                warning: Color(hex: 0x98926C),
                error: Color(hex: 0xBE5E5E),
                separator: Color.white.opacity(0.30)
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
                footerBackground: Color(red: 0.63, green: 0.44, blue: 0.27).opacity(0.35),
                background: Color(red: 0.14, green: 0.09, blue: 0.05),
                groupedBG: Color(red: 0.18, green: 0.11, blue: 0.07),
                surface: Color(red: 0.24, green: 0.15, blue: 0.09),
                surfaceElevated: Color(red: 0.31, green: 0.20, blue: 0.12),
                accentSecondary: Color(red: 0.72, green: 0.55, blue: 0.38),
                textPrimary: Color(red: 0.97, green: 0.92, blue: 0.84),
                textSecondary: Color(red: 0.92, green: 0.84, blue: 0.73),
                textTertiary: Color(red: 0.84, green: 0.74, blue: 0.61),
                runeText: Color(red: 0.96, green: 0.74, blue: 0.45),
                success: Color(hex: 0x68A878),
                warning: Color(hex: 0x98926C),
                error: Color(hex: 0xBE5E5E),
                separator: Color(red: 0.95, green: 0.88, blue: 0.75).opacity(0.35)
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
                footerBackground: Color(red: 0.33, green: 0.53, blue: 0.66).opacity(0.25),
                background: Color(red: 0.03, green: 0.12, blue: 0.19),
                groupedBG: Color(red: 0.04, green: 0.15, blue: 0.24),
                surface: Color(red: 0.08, green: 0.22, blue: 0.33),
                surfaceElevated: Color(red: 0.16, green: 0.33, blue: 0.46),
                accentSecondary: Color(red: 0.42, green: 0.62, blue: 0.76),
                textPrimary: Color(red: 0.95, green: 0.98, blue: 1.00),
                textSecondary: Color(red: 0.86, green: 0.93, blue: 0.98),
                textTertiary: Color(red: 0.72, green: 0.83, blue: 0.92),
                runeText: Color(red: 0.58, green: 0.86, blue: 1.00),
                success: Color(hex: 0x68A878),
                warning: Color(hex: 0x98926C),
                error: Color(hex: 0xBE5E5E),
                separator: Color(red: 0.82, green: 0.90, blue: 0.97).opacity(0.35)
            )
        }
    }
}
