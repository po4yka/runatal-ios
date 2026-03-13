//
//  GlassCard.swift
//  RunicQuotes
//
//  Created by Claude on 07.10.25.
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
    @Environment(\.runicTheme) private var runicTheme

    // MARK: - Initialization

    /// New design-system initializer using glass intensity tokens.
    init(
        intensity: DesignTokens.GlassIntensity = .medium,
        cornerRadius: CGFloat = DesignTokens.CornerRadius.xl,
        shadowRadius: CGFloat = 10,
        @ViewBuilder content: () -> Content,
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
        @ViewBuilder content: () -> Content,
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
        LiquidCard(
            palette: self.palette,
            role: self.role,
            cornerRadius: self.cornerRadius,
            shadowRadius: self.shadowRadius,
            interactive: self.intensity == .strong,
        ) {
            self.content
        }
    }

    private var palette: AppThemePalette {
        AppThemePalette.themed(self.runicTheme, for: self.colorScheme)
    }

    private var role: LiquidSurfaceRole {
        if self.reduceTransparency {
            return .content
        }
        switch self.intensity {
        case .strong:
            return .floatingCallout
        case .medium:
            return .chrome
        case .light, .none:
            return self.opacity.value > 0.55 ? .chrome : .inset
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
            endPoint: .bottomTrailing,
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
