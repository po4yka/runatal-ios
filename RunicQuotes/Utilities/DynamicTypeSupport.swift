//
//  DynamicTypeSupport.swift
//  RunicQuotes
//
//  Created by Claude on 13.11.25.
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
        maxSize: CGFloat = 60,
    ) -> some View {
        modifier(RunicDynamicTypeModifier(
            script: script,
            font: font,
            textStyle: style,
            minSize: minSize,
            maxSize: maxSize,
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

    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    func body(content: Content) -> some View {
        content
            .font(
                .custom(
                    RunicFontConfiguration.fontName(for: self.script, font: self.font),
                    size: self.scaledSize,
                    relativeTo: self.textStyle,
                ),
            )
            .minimumScaleFactor(0.5)
            .lineLimit(nil)
    }

    private var scaledSize: CGFloat {
        // Determine base size from text style.
        let baseSize: CGFloat = switch self.textStyle {
        case .largeTitle:
            34
        case .title:
            28
        case .title2:
            22
        case .title3:
            20
        case .headline:
            17
        case .body:
            17
        case .callout:
            16
        case .subheadline:
            15
        case .footnote:
            13
        case .caption:
            12
        case .caption2:
            11
        @unknown default:
            17
        }

        // Scale based on dynamic type size
        let scaleFactor = self.dynamicTypeSize.scaleFactor
        let scaled = baseSize * scaleFactor

        // Clamp to min/max range
        return min(max(scaled, self.minSize), self.maxSize)
    }
}

// MARK: - Dynamic Type Size Extension

extension DynamicTypeSize {
    /// Scale factor relative to default (.large)
    var scaleFactor: CGFloat {
        switch self {
        case .xSmall:
            return 0.8
        case .small:
            return 0.9
        case .medium:
            return 0.95
        case .large:
            return 1.0
        case .xLarge:
            return 1.1
        case .xxLarge:
            return 1.2
        case .xxxLarge:
            return 1.3
        case .accessibility1:
            return 1.5
        case .accessibility2:
            return 1.7
        case .accessibility3:
            return 2.0
        case .accessibility4:
            return 2.3
        case .accessibility5:
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
    func reduceMotionSensitiveAnimation(
        _ animation: Animation?,
        value: some Equatable,
    ) -> some View {
        modifier(ReduceMotionModifier(animation: animation, value: value))
    }
}

struct ReduceMotionModifier<V: Equatable>: ViewModifier {
    let animation: Animation?
    let value: V

    @Environment(\.accessibilityReduceMotion) var reduceMotion

    func body(content: Content) -> some View {
        if self.reduceMotion {
            content
        } else {
            content.animation(self.animation, value: self.value)
        }
    }
}

// MARK: - Accessibility Environment Helper

/// Helper to retrieve accessibility settings
struct AccessibilitySettings {
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @Environment(\.accessibilityReduceTransparency) var reduceTransparency
    @Environment(\.accessibilityDifferentiateWithoutColor) var differentiateWithoutColor

    var isAccessibilitySize: Bool {
        self.dynamicTypeSize.isAccessibilitySize
    }

    var shouldReduceAnimations: Bool {
        self.reduceMotion
    }

    var shouldReduceTransparency: Bool {
        self.reduceTransparency
    }
}
