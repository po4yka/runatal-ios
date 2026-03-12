//
//  DesignTokens.swift
//  RunicQuotes
//
//  Created by Claude on 2026-03-12.
//

import SwiftUI

// MARK: - Design Tokens

/// Centralized design tokens for spacing, corner radius, and glass materials.
/// Based on the Scandinavian cold-slate design system with 4px base grid.
enum DesignTokens: Sendable {

    // MARK: - Spacing

    /// 4px base grid spacing scale.
    enum Spacing: Sendable {
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
    enum CornerRadius: Sendable {
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

    // MARK: - Glass Material

    /// Liquid glass intensity levels for glassmorphism components.
    enum GlassIntensity: Sendable {
        case strong
        case medium
        case light

        /// Blur radius in points.
        var blurRadius: CGFloat {
            switch self {
            case .strong: return 60
            case .medium: return 40
            case .light: return 24
            }
        }

        /// Color saturation multiplier.
        var saturation: Double {
            switch self {
            case .strong: return 2.0
            case .medium: return 1.8
            case .light: return 1.5
            }
        }

        /// Corresponding SwiftUI Material.
        var material: Material {
            switch self {
            case .strong: return .regularMaterial
            case .medium: return .thinMaterial
            case .light: return .ultraThinMaterial
            }
        }
    }

    // MARK: - Glass Colors

    /// Adaptive glass background, border, and highlight colors for dark/light modes.
    enum GlassColor: Sendable {
        /// Glass background overlay color.
        static func background(for colorScheme: ColorScheme) -> Color {
            switch colorScheme {
            case .dark:
                return Color(red: 18/255, green: 24/255, blue: 38/255).opacity(0.52)
            case .light:
                return Color(red: 252/255, green: 253/255, blue: 255/255).opacity(0.58)
            @unknown default:
                return Color(red: 18/255, green: 24/255, blue: 38/255).opacity(0.52)
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
