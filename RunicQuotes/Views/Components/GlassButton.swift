//
//  GlassButton.swift
//  RunicQuotes
//
//  Created by Claude on 2025-11-15.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// A button component with liquid glass/glassmorphism design
struct GlassButton: View {
    // MARK: - Properties

    let title: String
    let icon: String?
    let action: () -> Void

    let opacity: GlassOpacity
    let blur: Material
    let cornerRadius: CGFloat
    let borderWidth: CGFloat

    @State private var isPressed = false
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    // MARK: - Initialization

    init(
        _ title: String,
        icon: String? = nil,
        opacity: GlassOpacity = .low,
        blur: Material = .thinMaterial,
        cornerRadius: CGFloat = 12,
        borderWidth: CGFloat = 1,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.opacity = opacity
        self.blur = blur
        self.cornerRadius = cornerRadius
        self.borderWidth = borderWidth
        self.action = action
    }

    // MARK: - Body

    var body: some View {
        Button(action: {
            triggerHapticIfAvailable()
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
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background {
                ZStack {
                    // Glass blur effect
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(blur)
                        .opacity(isPressed ? opacity.value * 1.3 : opacity.value)

                    // Gradient border
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.4),
                                    .white.opacity(0.2),
                                    .white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: borderWidth
                        )
                }
            }
            .shadow(
                color: .black.opacity(0.2),
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

    private func triggerHapticIfAvailable() {
#if canImport(UIKit)
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
#endif
    }
}

// MARK: - Convenience Variants

extension GlassButton {
    /// Create a primary glass button (more prominent)
    static func primary(
        _ title: String,
        icon: String? = nil,
        action: @escaping () -> Void
    ) -> GlassButton {
        GlassButton(
            title,
            icon: icon,
            opacity: .mediumLow,
            blur: .regularMaterial,
            action: action
        )
    }

    /// Create a secondary glass button (less prominent)
    static func secondary(
        _ title: String,
        icon: String? = nil,
        action: @escaping () -> Void
    ) -> GlassButton {
        GlassButton(
            title,
            icon: icon,
            opacity: .veryLow,
            blur: .ultraThinMaterial,
            action: action
        )
    }

    /// Create a compact glass button (smaller padding)
    static func compact(
        _ title: String,
        icon: String? = nil,
        action: @escaping () -> Void
    ) -> GlassButton {
        GlassButton(
            title,
            icon: icon,
            opacity: .low,
            blur: .thinMaterial,
            cornerRadius: 10,
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
            // Default button
            GlassButton("Default Button", icon: "star.fill") {
                // Preview action
            }

            // Primary button
            GlassButton.primary("Primary Button", icon: "arrow.right.circle.fill") {
                // Preview action
            }

            // Secondary button
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
        }
        .padding()
    }
}
