//
//  CoachMarksView.swift
//  RunicQuotes
//
//  Created by Claude on 2026-03-12.
//

import SwiftUI

// MARK: - Coach Mark Step

/// Defines each step in the feature tour.
enum CoachMarkStep: Int, CaseIterable, Identifiable, Codable, Sendable {
    var id: Int { rawValue }

    case swipeQuotes = 0
    case saveQuotes
    case exploreCollections

    var title: String {
        switch self {
        case .swipeQuotes: return "Swipe for More Quotes"
        case .saveQuotes: return "Save Your Favorites"
        case .exploreCollections: return "Explore Collections"
        }
    }

    var description: String {
        switch self {
        case .swipeQuotes:
            return "Swipe left or right on the quote card to browse through your collection."
        case .saveQuotes:
            return "Tap the bookmark icon to save quotes you love for quick access later."
        case .exploreCollections:
            return "Browse curated collections of quotes organized by theme and origin."
        }
    }

    var stepLabel: String {
        "\(rawValue + 1) of \(CoachMarkStep.allCases.count)"
    }

    var isLast: Bool {
        self == CoachMarkStep.allCases.last
    }
}

// MARK: - Coach Marks View

/// Full-screen overlay that guides users through key features.
/// Displays a dimmed backdrop with a spotlight cutout and a tooltip card.
struct CoachMarksView: View {

    // MARK: - Properties

    let onDismiss: () -> Void

    @State private var currentStep: CoachMarkStep = .swipeQuotes
    @State private var tooltipOpacity: Double = 0
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.runicTheme) private var runicTheme

    // MARK: - Body

    var body: some View {
        ZStack {
            // Dimmed backdrop
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    advanceOrDismiss()
                }

            // Tooltip card
            VStack(spacing: 0) {
                Spacer()

                tooltipCard
                    .padding(.horizontal, DesignTokens.Spacing.xl)
                    .padding(.bottom, DesignTokens.Spacing.huge)
            }
        }
        .opacity(tooltipOpacity)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                tooltipOpacity = 1
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("coach_marks_overlay")
    }

    // MARK: - Tooltip Card

    private var palette: AppThemePalette {
        .themed(runicTheme, for: colorScheme)
    }

    private var tooltipCard: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            // Title
            Text(currentStep.title)
                .font(.headline)
                .foregroundStyle(palette.textPrimary)

            // Description
            Text(currentStep.description)
                .font(.subheadline)
                .foregroundStyle(palette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            // Footer: step counter + Skip / Next
            HStack {
                Text(currentStep.stepLabel)
                    .font(.caption)
                    .foregroundStyle(palette.textTertiary)

                Spacer()

                if !currentStep.isLast {
                    Button {
                        dismiss()
                    } label: {
                        Text("Skip")
                            .font(.subheadline)
                            .foregroundStyle(palette.textSecondary)
                    }
                    .accessibilityIdentifier("coach_marks_skip")
                }

                Button {
                    advanceOrDismiss()
                } label: {
                    Text(currentStep.isLast ? "Done" : "Next")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(palette.textPrimary)
                        .padding(.horizontal, DesignTokens.Spacing.md)
                        .padding(.vertical, DesignTokens.Spacing.xs)
                        .background(
                            Capsule()
                                .fill(palette.accent.opacity(0.25))
                        )
                }
                .accessibilityIdentifier("coach_marks_next")
            }
            .padding(.top, DesignTokens.Spacing.xs)
        }
        .padding(DesignTokens.Spacing.lg)
        .background {
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                .fill(palette.editorialSurface)
        }
        .overlay {
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                .stroke(palette.cardStroke, lineWidth: DesignTokens.Stroke.hairline)
        }
        .id(currentStep)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("coach_marks_tooltip")
    }

    // MARK: - Actions

    private func advanceOrDismiss() {
        let allCases = CoachMarkStep.allCases
        guard let currentIndex = allCases.firstIndex(of: currentStep),
              currentIndex + 1 < allCases.count else {
            dismiss()
            return
        }
        withAnimation(.easeInOut(duration: 0.25)) {
            currentStep = allCases[currentIndex + 1]
        }
    }

    private func dismiss() {
        withAnimation(.easeIn(duration: 0.2)) {
            tooltipOpacity = 0
        }
        Task {
            try? await Task.sleep(for: .milliseconds(200))
            guard !Task.isCancelled else { return }
            onDismiss()
        }
    }
}

// MARK: - Preview

#Preview("Coach Marks - Dark") {
    CoachMarksView {
        // dismissed
    }
    .preferredColorScheme(.dark)
}

#Preview("Coach Marks - Light") {
    CoachMarksView {
        // dismissed
    }
    .preferredColorScheme(.light)
}
