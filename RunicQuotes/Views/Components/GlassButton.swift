//
//  GlassButton.swift
//  RunicQuotes
//
//  Created by Claude on 07.10.25.
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
    @Environment(\.runicTheme) private var runicTheme

    // MARK: - Initialization

    /// New design-system initializer using glass intensity tokens.
    init(
        _ title: String,
        icon: String? = nil,
        hapticTier: HapticTier? = nil,
        intensity: DesignTokens.GlassIntensity = .medium,
        cornerRadius: CGFloat = DesignTokens.CornerRadius.sm,
        action: @escaping () -> Void,
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
        action: @escaping () -> Void,
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
        Button(
            action: {
                if let hapticTier {
                    Haptics.trigger(hapticTier)
                }
                self.action()
            },
            label: {
                HStack(spacing: 8) {
                    if let icon {
                        Image(systemName: icon)
                            .font(.body.weight(.medium))
                            .accessibilityHidden(true)
                    }

                    if !self.title.isEmpty {
                        Text(self.title)
                            .font(.body.weight(.medium))
                    }
                }
                .foregroundStyle(self.isPrimary ? Color.white : self.palette.textPrimary)
                .padding(.horizontal, DesignTokens.Spacing.lg)
                .padding(.vertical, DesignTokens.Spacing.sm)
                .background {
                    self.buttonBackground
                }
                .shadow(
                    color: self.palette.shadowColor.opacity(self.isPrimary ? 1 : 0.78),
                    radius: self.isPressed ? 4 : 8,
                    x: 0,
                    y: self.isPressed ? 2 : 4,
                )
                .scaleEffect(self.isPressed ? 0.96 : 1.0)
            },
        )
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if self.reduceMotion {
                        self.isPressed = true
                    } else {
                        withAnimation(.easeInOut(duration: 0.1)) {
                            self.isPressed = true
                        }
                    }
                }
                .onEnded { _ in
                    if self.reduceMotion {
                        self.isPressed = false
                    } else {
                        withAnimation(.easeInOut(duration: 0.1)) {
                            self.isPressed = false
                        }
                    }
                },
        )
        .accessibilityAddTraits(.isButton)
    }

    private var palette: AppThemePalette {
        AppThemePalette.themed(self.runicTheme, for: self.colorScheme)
    }

    private var isPrimary: Bool {
        self.intensity == .strong || self.opacity == .low
    }

    private var buttonBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: self.cornerRadius)
                .fill(self.backgroundFill)

            if self.isPressed {
                RoundedRectangle(cornerRadius: self.cornerRadius)
                    .fill(self.palette.highlight)
            }

            RoundedRectangle(cornerRadius: self.cornerRadius)
                .strokeBorder(self.borderColor, lineWidth: DesignTokens.Stroke.hairline)
        }
    }

    private var backgroundFill: some ShapeStyle {
        if self.isPrimary {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [self.palette.accent, self.palette.ctaAccent],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing,
                ),
            )
        }

        return AnyShapeStyle(
            LinearGradient(
                colors: [self.palette.editorialSurface, self.palette.editorialInset],
                startPoint: .topLeading,
                endPoint: .bottomTrailing,
            ),
        )
    }

    private var borderColor: Color {
        self.isPrimary ? self.palette.strongCardStroke : self.palette.cardStroke
    }
}

// MARK: - Convenience Variants

extension GlassButton {
    /// Create a primary glass button (more prominent)
    static func primary(
        _ title: String,
        icon: String? = nil,
        hapticTier: HapticTier? = nil,
        action: @escaping () -> Void,
    ) -> GlassButton {
        GlassButton(
            title,
            icon: icon,
            hapticTier: hapticTier,
            intensity: .strong,
            action: action,
        )
    }

    /// Create a secondary glass button (less prominent)
    static func secondary(
        _ title: String,
        icon: String? = nil,
        hapticTier: HapticTier? = nil,
        action: @escaping () -> Void,
    ) -> GlassButton {
        GlassButton(
            title,
            icon: icon,
            hapticTier: hapticTier,
            intensity: .light,
            action: action,
        )
    }

    /// Create a compact glass button (smaller padding)
    static func compact(
        _ title: String,
        icon: String? = nil,
        hapticTier: HapticTier? = nil,
        action: @escaping () -> Void,
    ) -> GlassButton {
        GlassButton(
            title,
            icon: icon,
            hapticTier: hapticTier,
            intensity: .light,
            cornerRadius: DesignTokens.CornerRadius.sm,
            action: action,
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
            endPoint: .bottomTrailing,
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
