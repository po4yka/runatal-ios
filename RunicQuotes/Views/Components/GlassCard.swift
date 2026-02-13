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
    let opacity: GlassOpacity
    let blur: Material
    let cornerRadius: CGFloat
    let shadowRadius: CGFloat
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    // MARK: - Initialization

    init(
        opacity: GlassOpacity = .mediumLow,
        blur: Material = .ultraThinMaterial,
        cornerRadius: CGFloat = 20,
        shadowRadius: CGFloat = 10,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
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
            .shadow(
                color: .black.opacity(0.22),
                radius: shadowRadius,
                x: 0,
                y: 4
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
            // Default glass card
            GlassCard {
                VStack(spacing: 10) {
                    Text("Default Glass Card")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Medium-low opacity with ultra-thin material")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }

            // Light glass card
            GlassCard(
                opacity: .veryLow,
                blur: .ultraThinMaterial
            ) {
                VStack(spacing: 10) {
                    Text("Light Glass Card")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Very low opacity with ultra-thin material")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }

            // Heavy glass card
            GlassCard(
                opacity: .medium,
                blur: .regularMaterial
            ) {
                VStack(spacing: 10) {
                    Text("Heavy Glass Card")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Medium opacity with regular material")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .padding()
    }
}
