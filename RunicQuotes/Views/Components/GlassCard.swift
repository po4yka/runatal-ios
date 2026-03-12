//
//  GlassCard.swift
//  RunicQuotes
//
//  Created by Claude on 2025-11-15.
//

import SwiftUI

/// A card component with liquid glass/glassmorphism design
struct GlassCard<Content: View>: View {
    // MARK: - Properties

    let content: Content
    let intensity: DesignTokens.GlassIntensity?
    let opacity: GlassOpacity
    let blur: Material
    let cornerRadius: CGFloat
    let shadowRadius: CGFloat
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Initialization

    /// New design-system initializer using glass intensity tokens.
    init(
        intensity: DesignTokens.GlassIntensity = .medium,
        cornerRadius: CGFloat = DesignTokens.CornerRadius.xl,
        shadowRadius: CGFloat = 10,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.intensity = intensity
        self.opacity = .mediumLow
        self.blur = intensity.material
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
    }

    /// Legacy initializer for backward compatibility.
    init(
        opacity: GlassOpacity,
        blur: Material = .ultraThinMaterial,
        cornerRadius: CGFloat = 20,
        shadowRadius: CGFloat = 10,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.intensity = nil
        self.opacity = opacity
        self.blur = blur
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
    }

    // MARK: - Body

    var body: some View {
        content
            .padding()
            .background {
                ZStack {
                    if let intensity {
                        // New design-system glass rendering
                        adaptiveGlassBackground(intensity: intensity)
                    } else {
                        // Legacy glass rendering
                        legacyGlassBackground
                    }
                }
            }
            .shadow(
                color: .black.opacity(0.22),
                radius: shadowRadius,
                x: 0,
                y: 4
            )
    }

    // MARK: - Glass Rendering

    @ViewBuilder
    private func adaptiveGlassBackground(intensity: DesignTokens.GlassIntensity) -> some View {
        // Material blur layer
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(
                reduceTransparency
                    ? AnyShapeStyle(Color.black.opacity(0.62))
                    : AnyShapeStyle(intensity.material)
            )

        if !reduceTransparency {
            // Glass background tint
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(DesignTokens.GlassColor.background(for: colorScheme))

            // Glass border
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(
                    DesignTokens.GlassColor.border(for: colorScheme),
                    lineWidth: 0.5
                )

            // Inner highlight
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [
                            DesignTokens.GlassColor.highlight(for: colorScheme),
                            .clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .center
                    )
                )
                .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private var legacyGlassBackground: some View {
        // Glass blur effect
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(
                reduceTransparency
                    ? AnyShapeStyle(Color.black.opacity(0.62))
                    : AnyShapeStyle(blur)
            )
            .opacity(reduceTransparency ? 1.0 : opacity.value)

        // Inner highlight -- simulates top-left light source
        if !reduceTransparency {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.07),
                            .clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .center
                    )
                )
                .allowsHitTesting(false)
        }
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
            // Strong intensity glass card
            GlassCard(intensity: .strong) {
                VStack(spacing: 10) {
                    Text("Strong Glass Card")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("60px blur, 2.0 saturation")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }

            // Medium intensity glass card (default)
            GlassCard {
                VStack(spacing: 10) {
                    Text("Medium Glass Card")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("40px blur, 1.8 saturation")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }

            // Light intensity glass card
            GlassCard(intensity: .light) {
                VStack(spacing: 10) {
                    Text("Light Glass Card")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("24px blur, 1.5 saturation")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }

            // Legacy glass card (backward compat)
            GlassCard(opacity: .high, blur: .ultraThinMaterial) {
                VStack(spacing: 10) {
                    Text("Legacy Glass Card")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("Old API still works")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
        }
        .padding()
    }
}
