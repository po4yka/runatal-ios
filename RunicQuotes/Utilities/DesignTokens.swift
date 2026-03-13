//
//  DesignTokens.swift
//  RunicQuotes
//
//  Created by Claude on 12.03.26.
//

import SwiftUI

// MARK: - Design Tokens

/// Centralized design tokens for spacing, typography, motion, and liquid surfaces.
enum DesignTokens {

    // MARK: - Spacing

    /// 4px base grid spacing scale.
    enum Spacing {
        /// 4pt
        static let xxs: CGFloat = 4
        /// 8pt
        static let xs: CGFloat = 8
        /// 12pt
        static let sm: CGFloat = 12
        /// 16pt
        static let md: CGFloat = 16
        /// 20pt
        static let lg: CGFloat = 20
        /// 24pt
        static let xl: CGFloat = 24
        /// 32pt
        static let xxl: CGFloat = 32
        /// 40pt
        static let xxxl: CGFloat = 40
        /// 48pt
        static let huge: CGFloat = 48
        /// 64pt
        static let massive: CGFloat = 64
    }

    // MARK: - Corner Radius

    /// iOS 26 shape language corner radius tokens.
    enum CornerRadius {
        /// 6pt
        static let xs: CGFloat = 6
        /// 10pt
        static let sm: CGFloat = 10
        /// 14pt
        static let md: CGFloat = 14
        /// 18pt
        static let lg: CGFloat = 18
        /// 22pt
        static let xl: CGFloat = 22
        /// 26pt
        static let xxl: CGFloat = 26
        /// 30pt
        static let xxxl: CGFloat = 30
        /// 100pt -- pill/circle shapes
        static let full: CGFloat = 100
    }

    // MARK: - Typography

    enum Typography {
        static let eyebrow = Font.system(.caption, design: .rounded).weight(.semibold)
        static let display = Font.system(size: 42, weight: .semibold, design: .serif)
        static let hero = Font.system(size: 38, weight: .semibold, design: .serif)
        static let heroCompact = Font.system(size: 30, weight: .semibold, design: .serif)
        static let pageTitle = Font.system(.title2, design: .serif).weight(.semibold)
        static let sectionTitle = Font.system(.title3, design: .serif).weight(.semibold)
        static let cardTitle = Font.system(.headline, design: .serif).weight(.semibold)
        static let bodyLarge = Font.system(.body, design: .default).weight(.medium)
        static let body = Font.body
        static let bodyEmphasis = Font.body.weight(.semibold)
        static let supportingBody = Font.system(.subheadline, design: .default)
        static let callout = Font.callout
        static let label = Font.system(.caption, design: .rounded).weight(.medium)
        static let controlLabel = Font.system(.footnote, design: .rounded).weight(.semibold)
        static let listMeta = Font.system(.footnote, design: .rounded).weight(.medium)
        static let widgetMeta = Font.system(.caption, design: .rounded).weight(.medium)
        static let metadata = listMeta
        static let toolbarLabel = controlLabel
    }

    // MARK: - Motion

    enum Motion {
        static let quoteTransition = Animation.spring(response: 0.42, dampingFraction: 0.84)
        static let emphasis = Animation.easeInOut(duration: 0.24)
        static let themeTransition = Animation.easeInOut(duration: 0.35)
        static let reveal = Animation.spring(response: 0.48, dampingFraction: 0.82)
    }

    // MARK: - Stroke

    enum Stroke {
        static let hairline: CGFloat = 1
        static let emphasis: CGFloat = 1.25
    }

    // MARK: - Elevation

    enum Elevation {
        static let low: CGFloat = 6
        static let medium: CGFloat = 12
        static let hero: CGFloat = 22
        static let chrome: CGFloat = 16
    }

    // MARK: - Liquid Glass

    /// Legacy intensity levels kept for compatibility with older wrappers.
    enum GlassIntensity {
        case strong
        case medium
        case light

        /// Blur radius in points.
        var blurRadius: CGFloat {
            switch self {
            case .strong: 60
            case .medium: 40
            case .light: 24
            }
        }

        /// Color saturation multiplier.
        var saturation: Double {
            switch self {
            case .strong: 2.0
            case .medium: 1.8
            case .light: 1.5
            }
        }

        /// Corresponding SwiftUI Material.
        var material: Material {
            switch self {
            case .strong: .regularMaterial
            case .medium: .thinMaterial
            case .light: .ultraThinMaterial
            }
        }
    }

    // MARK: - Glass Colors

    /// Adaptive glass background, border, and highlight colors for dark/light modes.
    enum GlassColor {
        /// Glass background overlay color.
        static func background(for colorScheme: ColorScheme) -> Color {
            switch colorScheme {
            case .dark:
                return Color(red: 18 / 255, green: 24 / 255, blue: 38 / 255).opacity(0.52)
            case .light:
                return Color(red: 252 / 255, green: 253 / 255, blue: 255 / 255).opacity(0.58)
            @unknown default:
                return Color(red: 18 / 255, green: 24 / 255, blue: 38 / 255).opacity(0.52)
            }
        }

        /// Glass border color.
        static func border(for colorScheme: ColorScheme) -> Color {
            switch colorScheme {
            case .dark:
                return Color.white.opacity(0.10)
            case .light:
                return Color.white.opacity(0.55)
            @unknown default:
                return Color.white.opacity(0.10)
            }
        }

        /// Glass inner highlight color.
        static func highlight(for colorScheme: ColorScheme) -> Color {
            switch colorScheme {
            case .dark:
                return Color.white.opacity(0.06)
            case .light:
                return Color.white.opacity(0.9)
            @unknown default:
                return Color.white.opacity(0.06)
            }
        }
    }
}
