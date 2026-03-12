//
//  GlassButton.swift
//  RunicQuotes
//
//  Created by Claude on 2025-11-15.
//

import SwiftUI

/// A button component with liquid glass/glassmorphism design
struct GlassButton: View {
    // MARK: - Properties

    let title: String
    let icon: String?
    let hapticTier: HapticTier?
    let action: () -> Void

    let intensity: DesignTokens.GlassIntensity?
    let opacity: GlassOpacity
    let blur: Material
    let cornerRadius: CGFloat

    @State private var isPressed = false
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Initialization

    /// New design-system initializer using glass intensity tokens.
    init(
        _ title: String,
        icon: String? = nil,
        hapticTier: HapticTier? = nil,
        intensity: DesignTokens.GlassIntensity = .medium,
        cornerRadius: CGFloat = DesignTokens.CornerRadius.sm,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.hapticTier = hapticTier
        self.intensity = intensity
        self.opacity = .low
        self.blur = intensity.material
        self.cornerRadius = cornerRadius
        self.action = action
    }

    /// Legacy initializer for backward compatibility.
    init(
        _ title: String,
        icon: String? = nil,
        hapticTier: HapticTier? = nil,
        opacity: GlassOpacity,
        blur: Material = .thinMaterial,
        cornerRadius: CGFloat = 12,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.hapticTier = hapticTier
        self.intensity = nil
        self.opacity = opacity
        self.blur = blur
        self.cornerRadius = cornerRadius
        self.action = action
    }

    // MARK: - Body

    var body: some View {
        Button(action: {
            if let hapticTier {
                Haptics.trigger(hapticTier)
            }
            action()
        }) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.body.weight(.medium))
                        .accessibilityHidden(true)
                }

                if !title.isEmpty {
                    Text(title)
                        .font(.body.weight(.medium))
                }
            }
            .foregroundStyle(.white)
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.vertical, DesignTokens.Spacing.sm)
            .background {
                if let intensity {
                    adaptiveGlassBackground(intensity: intensity)
                } else {
                    legacyGlassBackground
                }
            }
            .shadow(
                color: .black.opacity(0.22),
                radius: isPressed ? 4 : 8,
                x: 0,
                y: isPressed ? 2 : 4
            )
            .scaleEffect(isPressed ? 0.96 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if reduceMotion {
                        isPressed = true
                    } else {
                        withAnimation(.easeInOut(duration: 0.1)) {
                            isPressed = true
                        }
                    }
                }
                .onEnded { _ in
                    if reduceMotion {
                        isPressed = false
                    } else {
                        withAnimation(.easeInOut(duration: 0.1)) {
                            isPressed = false
                        }
                    }
                }
        )
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Glass Rendering

    @ViewBuilder
    private func adaptiveGlassBackground(intensity: DesignTokens.GlassIntensity) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(intensity.material)

            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(DesignTokens.GlassColor.background(for: colorScheme))
                .opacity(isPressed ? 1.3 : 1.0)

            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(
                    DesignTokens.GlassColor.border(for: colorScheme),
                    lineWidth: 0.5
                )
        }
    }

    @ViewBuilder
    private var legacyGlassBackground: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(blur)
            .opacity(isPressed ? opacity.value * 1.3 : opacity.value)
    }
}

// MARK: - Convenience Variants

extension GlassButton {
    /// Create a primary glass button (more prominent)
    static func primary(
        _ title: String,
        icon: String? = nil,
        hapticTier: HapticTier? = nil,
        action: @escaping () -> Void
    ) -> GlassButton {
        GlassButton(
            title,
            icon: icon,
            hapticTier: hapticTier,
            intensity: .strong,
            action: action
        )
    }

    /// Create a secondary glass button (less prominent)
    static func secondary(
        _ title: String,
        icon: String? = nil,
        hapticTier: HapticTier? = nil,
        action: @escaping () -> Void
    ) -> GlassButton {
        GlassButton(
            title,
            icon: icon,
            hapticTier: hapticTier,
            intensity: .light,
            action: action
        )
    }

    /// Create a compact glass button (smaller padding)
    static func compact(
        _ title: String,
        icon: String? = nil,
        hapticTier: HapticTier? = nil,
        action: @escaping () -> Void
    ) -> GlassButton {
        GlassButton(
            title,
            icon: icon,
            hapticTier: hapticTier,
            intensity: .light,
            cornerRadius: DesignTokens.CornerRadius.sm,
            action: action
        )
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        // Background gradient
        LinearGradient(
            colors: [.black, Color(white: 0.1), .black],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        VStack(spacing: 30) {
            // Default button (medium intensity)
            GlassButton("Default Button", icon: "star.fill") {
                // Preview action
            }

            // Primary button (strong intensity)
            GlassButton.primary("Primary Button", icon: "arrow.right.circle.fill") {
                // Preview action
            }

            // Secondary button (light intensity)
            GlassButton.secondary("Secondary Button", icon: "gear") {
                // Preview action
            }

            // Compact button
            GlassButton.compact("Compact Button") {
                // Preview action
            }

            // Icon-only button
            GlassButton("", icon: "shuffle") {
                // Preview action
            }

            // Legacy button (backward compat)
            GlassButton("Legacy", icon: "clock", opacity: .low, blur: .thinMaterial) {
                // Preview action
            }
        }
        .padding()
    }
}
