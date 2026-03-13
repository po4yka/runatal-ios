//
//  AppThemePalette.swift
//  RunicQuotes
//
//  Created by Claude on 13.02.26.
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

extension AppThemePalette {
    static func adaptive(for colorScheme: ColorScheme) -> AppThemePalette {
        self.themed(.obsidian, for: colorScheme)
    }

    static func themed(_ theme: AppTheme, for colorScheme: ColorScheme) -> AppThemePalette {
        switch (theme, colorScheme) {
        case (.obsidian, .dark):
            return self.obsidianDark
        case (.obsidian, .light):
            return self.obsidianLight
        case (.parchment, .dark):
            return self.parchmentDark
        case (.parchment, .light):
            return self.parchmentLight
        case (.nordicDawn, .dark):
            return self.nordicDawnDark
        case (.nordicDawn, .light):
            return self.nordicDawnLight
        @unknown default:
            return self.obsidianDark
        }
    }

    var heroBackgroundGradient: [Color] {
        [self.canvasBase, self.canvasElevated, self.canvasBase]
    }

    var immersiveBackgroundGradient: [Color] {
        [self.canvasBase, self.canvasSecondary, self.canvasBase]
    }

    var editorialSurface: Color {
        self.contentPlateElevated
    }

    var editorialInset: Color {
        self.insetPlate
    }

    var editorialMutedSurface: Color {
        self.groupedBG.opacity(0.76)
    }

    var cardStroke: Color {
        self.contentStroke
    }

    var strongCardStroke: Color {
        self.accent.opacity(0.34)
    }

    var chipFill: Color {
        self.chromeFallback
    }

    var chipSelectedFill: Color {
        self.accent
    }

    var chipSelectedForeground: Color {
        self.background
    }

    var ornament: Color {
        self.runeText.opacity(0.08)
    }

    var ornamentSecondary: Color {
        self.accent.opacity(0.07)
    }

    var shadowColor: Color {
        Color.black.opacity(0.16)
    }

    var highlight: Color {
        self.textPrimary.opacity(0.05)
    }

    var bannerBackground: Color {
        self.chromeFallback
    }

    var successFill: Color {
        self.success.opacity(0.15)
    }

    var warningFill: Color {
        self.warning.opacity(0.15)
    }

    var errorFill: Color {
        self.error.opacity(0.15)
    }

    var canvasBase: Color {
        self.background
    }

    var canvasSecondary: Color {
        self.groupedBG.opacity(0.96)
    }

    var canvasElevated: Color {
        self.surface.opacity(0.94)
    }

    var contentPlate: Color {
        self.surface.opacity(0.94)
    }

    var contentPlateElevated: Color {
        self.surfaceElevated.opacity(0.96)
    }

    var insetPlate: Color {
        self.groupedBG.opacity(0.72)
    }

    var chromeTint: Color {
        self.accent.opacity(0.22)
    }

    var chromeFill: Color {
        self.surface.opacity(0.42)
    }

    var chromeFallback: Color {
        self.surfaceElevated.opacity(0.78)
    }

    var contentStroke: Color {
        self.separator.opacity(0.6)
    }

    var chromeStroke: Color {
        self.separator.opacity(0.42)
    }

    var rowFill: Color {
        self.surface.opacity(0.88)
    }

    var rowInsetFill: Color {
        self.groupedBG.opacity(0.62)
    }

    var fieldFill: Color {
        self.surface.opacity(0.78)
    }

    var toolbarBadgeFill: Color {
        self.surfaceElevated.opacity(0.72)
    }

    var subtleAccentText: Color {
        self.accent.opacity(0.92)
    }

    private static let obsidianDark = AppThemePalette(
        appBackgroundGradient: [
            Color(hex: 0x080B11),
            Color(hex: 0x11161D),
            Color(hex: 0x1A202A),
            Color(hex: 0x12171F),
            Color(hex: 0x090C12),
        ],
        widgetBackgroundGradient: [
            Color(hex: 0x0B0F15),
            Color(hex: 0x171E28),
            Color(hex: 0x0B0F15),
        ],
        primaryText: Color(hex: 0xF4EFE6),
        secondaryText: Color(hex: 0xC3B8A7),
        tertiaryText: Color(hex: 0x8C857C),
        divider: Color(hex: 0x2F3743),
        accent: Color(hex: 0xC6A46A),
        ctaAccent: Color(hex: 0xA7824D),
        footerBackground: Color(hex: 0x181D25),
        background: Color(hex: 0x080B11),
        groupedBG: Color(hex: 0x11161D),
        surface: Color(hex: 0x181D25),
        surfaceElevated: Color(hex: 0x202733),
        accentSecondary: Color(hex: 0x8C6B3C),
        textPrimary: Color(hex: 0xF4EFE6),
        textSecondary: Color(hex: 0xC3B8A7),
        textTertiary: Color(hex: 0x8C857C),
        runeText: Color(hex: 0xE6D4B2),
        success: Color(hex: 0x7BAA7C),
        warning: Color(hex: 0xC8A45B),
        error: Color(hex: 0xC37A73),
        separator: Color(hex: 0x2F3743),
    )

    private static let obsidianLight = AppThemePalette(
        appBackgroundGradient: [
            Color(hex: 0xF3EEE6),
            Color(hex: 0xE8E2D7),
            Color(hex: 0xDDD6CA),
            Color(hex: 0xECE5DA),
            Color(hex: 0xF8F3EB),
        ],
        widgetBackgroundGradient: [
            Color(hex: 0xEEE7DA),
            Color(hex: 0xE2D9C9),
            Color(hex: 0xF7F1E7),
        ],
        primaryText: Color(hex: 0x211B15),
        secondaryText: Color(hex: 0x5D5347),
        tertiaryText: Color(hex: 0x8C7F70),
        divider: Color(hex: 0xD2C6B6),
        accent: Color(hex: 0x8C6633),
        ctaAccent: Color(hex: 0xA17842),
        footerBackground: Color(hex: 0xE8E0D2),
        background: Color(hex: 0xF8F3EB),
        groupedBG: Color(hex: 0xF0E9DE),
        surface: Color(hex: 0xFBF7F0),
        surfaceElevated: Color(hex: 0xF4EBDD),
        accentSecondary: Color(hex: 0xB08B58),
        textPrimary: Color(hex: 0x211B15),
        textSecondary: Color(hex: 0x5D5347),
        textTertiary: Color(hex: 0x8C7F70),
        runeText: Color(hex: 0x6D522A),
        success: Color(hex: 0x4F7B55),
        warning: Color(hex: 0xA17A32),
        error: Color(hex: 0xA6524C),
        separator: Color(hex: 0xD2C6B6),
    )

    private static let parchmentDark = AppThemePalette(
        appBackgroundGradient: [
            Color(hex: 0x1A120C),
            Color(hex: 0x261B12),
            Color(hex: 0x3B2A1B),
            Color(hex: 0x2A1E14),
            Color(hex: 0x16100B),
        ],
        widgetBackgroundGradient: [
            Color(hex: 0x24190F),
            Color(hex: 0x3A2A1B),
            Color(hex: 0x24190F),
        ],
        primaryText: Color(hex: 0xF3E5CE),
        secondaryText: Color(hex: 0xDABF96),
        tertiaryText: Color(hex: 0xA88B67),
        divider: Color(hex: 0x57412C),
        accent: Color(hex: 0xD39D4B),
        ctaAccent: Color(hex: 0xBD8241),
        footerBackground: Color(hex: 0x312318),
        background: Color(hex: 0x16100B),
        groupedBG: Color(hex: 0x24190F),
        surface: Color(hex: 0x312318),
        surfaceElevated: Color(hex: 0x432F20),
        accentSecondary: Color(hex: 0x9F6931),
        textPrimary: Color(hex: 0xF3E5CE),
        textSecondary: Color(hex: 0xDABF96),
        textTertiary: Color(hex: 0xA88B67),
        runeText: Color(hex: 0xE8BE74),
        success: Color(hex: 0x7E9C67),
        warning: Color(hex: 0xC69A52),
        error: Color(hex: 0xC87A6A),
        separator: Color(hex: 0x57412C),
    )

    private static let parchmentLight = AppThemePalette(
        appBackgroundGradient: [
            Color(hex: 0xFBF2E4),
            Color(hex: 0xF3E5D0),
            Color(hex: 0xEAD8BE),
            Color(hex: 0xF6E8D6),
            Color(hex: 0xFFF8EF),
        ],
        widgetBackgroundGradient: [
            Color(hex: 0xF6E8D6),
            Color(hex: 0xE9D6B8),
            Color(hex: 0xFFF7EC),
        ],
        primaryText: Color(hex: 0x2F2215),
        secondaryText: Color(hex: 0x735A3F),
        tertiaryText: Color(hex: 0x9A7E60),
        divider: Color(hex: 0xDFC8A7),
        accent: Color(hex: 0xA96A28),
        ctaAccent: Color(hex: 0xB98042),
        footerBackground: Color(hex: 0xF1E0C7),
        background: Color(hex: 0xFFF8EF),
        groupedBG: Color(hex: 0xF8EDDD),
        surface: Color(hex: 0xFEF8F1),
        surfaceElevated: Color(hex: 0xF5E7D2),
        accentSecondary: Color(hex: 0xC58E53),
        textPrimary: Color(hex: 0x2F2215),
        textSecondary: Color(hex: 0x735A3F),
        textTertiary: Color(hex: 0x9A7E60),
        runeText: Color(hex: 0x8F581C),
        success: Color(hex: 0x5F8251),
        warning: Color(hex: 0xA37729),
        error: Color(hex: 0xAE5A46),
        separator: Color(hex: 0xDFC8A7),
    )

    private static let nordicDawnDark = AppThemePalette(
        appBackgroundGradient: [
            Color(hex: 0x0A141B),
            Color(hex: 0x13232E),
            Color(hex: 0x20384A),
            Color(hex: 0x162A36),
            Color(hex: 0x0C151D),
        ],
        widgetBackgroundGradient: [
            Color(hex: 0x0D1921),
            Color(hex: 0x1B3140),
            Color(hex: 0x0D1921),
        ],
        primaryText: Color(hex: 0xEAF4F7),
        secondaryText: Color(hex: 0xB8CCD6),
        tertiaryText: Color(hex: 0x819AA8),
        divider: Color(hex: 0x2A4352),
        accent: Color(hex: 0x8BC7D8),
        ctaAccent: Color(hex: 0x6BA6BB),
        footerBackground: Color(hex: 0x152833),
        background: Color(hex: 0x0A141B),
        groupedBG: Color(hex: 0x0F1C24),
        surface: Color(hex: 0x152833),
        surfaceElevated: Color(hex: 0x1E3543),
        accentSecondary: Color(hex: 0x6BA6BB),
        textPrimary: Color(hex: 0xEAF4F7),
        textSecondary: Color(hex: 0xB8CCD6),
        textTertiary: Color(hex: 0x819AA8),
        runeText: Color(hex: 0xBDE2ED),
        success: Color(hex: 0x78A890),
        warning: Color(hex: 0xB4A05A),
        error: Color(hex: 0xC27474),
        separator: Color(hex: 0x2A4352),
    )

    private static let nordicDawnLight = AppThemePalette(
        appBackgroundGradient: [
            Color(hex: 0xF5FAFB),
            Color(hex: 0xE8F1F4),
            Color(hex: 0xD8E6EB),
            Color(hex: 0xEEF5F7),
            Color(hex: 0xFBFEFE),
        ],
        widgetBackgroundGradient: [
            Color(hex: 0xEAF3F5),
            Color(hex: 0xD7E6EB),
            Color(hex: 0xF8FCFD),
        ],
        primaryText: Color(hex: 0x10212A),
        secondaryText: Color(hex: 0x49606C),
        tertiaryText: Color(hex: 0x728995),
        divider: Color(hex: 0xC8D7DD),
        accent: Color(hex: 0x3E7F92),
        ctaAccent: Color(hex: 0x5B9EB0),
        footerBackground: Color(hex: 0xE4EEF1),
        background: Color(hex: 0xFBFEFE),
        groupedBG: Color(hex: 0xF1F7F8),
        surface: Color(hex: 0xFFFFFF),
        surfaceElevated: Color(hex: 0xEAF2F4),
        accentSecondary: Color(hex: 0x5B9EB0),
        textPrimary: Color(hex: 0x10212A),
        textSecondary: Color(hex: 0x49606C),
        textTertiary: Color(hex: 0x728995),
        runeText: Color(hex: 0x28596B),
        success: Color(hex: 0x4D7A68),
        warning: Color(hex: 0x9A8747),
        error: Color(hex: 0xA55656),
        separator: Color(hex: 0xC8D7DD),
    )
}

extension Color {
    init(hex: UInt32) {
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue)
    }
}

extension AppTheme {
    var palette: AppThemePalette {
        AppThemePalette.themed(self, for: .dark)
    }
}
