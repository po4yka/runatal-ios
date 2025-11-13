//
//  DynamicTypeSupport.swift
//  RunicQuotes
//
//  Created by Claude on 2025-11-15.
//

import SwiftUI

// MARK: - Dynamic Type Text Styles

/// Extension to provide Dynamic Type support for runic text
extension View {
    /// Apply runic text style with Dynamic Type support
    func runicTextStyle(
        script: RunicScript,
        font: RunicFont,
        style: Font.TextStyle = .title,
        minSize: CGFloat = 20,
        maxSize: CGFloat = 60
    ) -> some View {
        modifier(RunicDynamicTypeModifier(
            script: script,
            font: font,
            textStyle: style,
            minSize: minSize,
            maxSize: maxSize
        ))
    }
}

/// Modifier that applies Dynamic Type to runic text
struct RunicDynamicTypeModifier: ViewModifier {
    let script: RunicScript
    let font: RunicFont
    let textStyle: Font.TextStyle
    let minSize: CGFloat
    let maxSize: CGFloat

    @Environment(\.sizeCategory) var sizeCategory
    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    func body(content: Content) -> some View {
        content
            .font(
                .custom(
                    RunicFontConfiguration.fontName(for: script, font: font),
                    size: scaledSize,
                    relativeTo: textStyle
                )
            )
            .minimumScaleFactor(0.5)
            .lineLimit(nil)
    }

    private var scaledSize: CGFloat {
        let baseSize: CGFloat

        // Determine base size from text style
        switch textStyle {
        case .largeTitle:
            baseSize = 34
        case .title:
            baseSize = 28
        case .title2:
            baseSize = 22
        case .title3:
            baseSize = 20
        case .headline:
            baseSize = 17
        case .body:
            baseSize = 17
        case .callout:
            baseSize = 16
        case .subheadline:
            baseSize = 15
        case .footnote:
            baseSize = 13
        case .caption:
            baseSize = 12
        case .caption2:
            baseSize = 11
        @unknown default:
            baseSize = 17
        }

        // Scale based on size category
        let scaleFactor = sizeCategory.scaleFactor
        let scaled = baseSize * scaleFactor

        // Clamp to min/max range
        return min(max(scaled, minSize), maxSize)
    }
}

// MARK: - Content Size Category Extension

extension ContentSizeCategory {
    /// Scale factor relative to default (.large)
    var scaleFactor: CGFloat {
        switch self {
        case .extraSmall:
            return 0.8
        case .small:
            return 0.9
        case .medium:
            return 0.95
        case .large:
            return 1.0
        case .extraLarge:
            return 1.1
        case .extraExtraLarge:
            return 1.2
        case .extraExtraExtraLarge:
            return 1.3
        case .accessibilityMedium:
            return 1.5
        case .accessibilityLarge:
            return 1.7
        case .accessibilityExtraLarge:
            return 2.0
        case .accessibilityExtraExtraLarge:
            return 2.3
        case .accessibilityExtraExtraExtraLarge:
            return 2.6
        @unknown default:
            return 1.0
        }
    }
}

// MARK: - Reduce Motion Support

/// Extension to check if Reduce Motion is enabled
extension View {
    /// Apply animation only if Reduce Motion is disabled
    func reduceMotionSensitiveAnimation<V: Equatable>(
        _ animation: Animation?,
        value: V
    ) -> some View {
        modifier(ReduceMotionModifier(animation: animation, value: value))
    }
}

struct ReduceMotionModifier<V: Equatable>: ViewModifier {
    let animation: Animation?
    let value: V

    @Environment(\.accessibilityReduceMotion) var reduceMotion

    func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            content.animation(animation, value: value)
        }
    }
}

// MARK: - Accessibility Environment Helper

/// Helper to retrieve accessibility settings
struct AccessibilitySettings {
    @Environment(\.sizeCategory) var sizeCategory
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @Environment(\.accessibilityReduceTransparency) var reduceTransparency
    @Environment(\.accessibilityDifferentiateWithoutColor) var differentiateWithoutColor

    var isAccessibilitySize: Bool {
        sizeCategory.isAccessibilityCategory
    }

    var shouldReduceAnimations: Bool {
        reduceMotion
    }

    var shouldReduceTransparency: Bool {
        reduceTransparency
    }
}
