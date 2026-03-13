//
//  OnboardingAtmosphereOption.swift
//  RunicQuotes
//
//  Created by Claude on 2026-03-13.
//

import SwiftUI

/// Selectable atmosphere card used in onboarding.
struct OnboardingAtmosphereOption: View {
    let script: RunicScript
    let title: String
    let subtitle: String
    let sampleLatin: String
    let selectedScript: RunicScript?
    let palette: AppThemePalette
    let onSelect: (RunicScript?) -> Void

    private var isSelected: Bool {
        selectedScript == script
    }

    private var runicSample: String {
        RunicTransliterator.transliterate(sampleLatin, to: script)
    }

    private var recommendedFont: RunicFont {
        RunicFontConfiguration.recommendedFont(for: script)
    }

    var body: some View {
        Button {
            onSelect(isSelected ? nil : script)
        } label: {
            GlassCard(
                intensity: isSelected ? .medium : .light,
                cornerRadius: DesignTokens.CornerRadius.lg,
                shadowRadius: isSelected ? 14 : 8
            ) {
                HStack(spacing: DesignTokens.Spacing.sm) {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                        HStack {
                            Text(title)
                                .font(.headline)
                                .foregroundStyle(palette.textPrimary)

                            Spacer()

                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.body)
                                    .foregroundStyle(palette.accent)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }

                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(palette.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(runicSample)
                            .runicTextStyle(
                                script: script,
                                font: recommendedFont,
                                style: .subheadline,
                                minSize: 14,
                                maxSize: 20
                            )
                            .foregroundStyle(palette.runeText)
                            .lineLimit(1)
                            .padding(.top, DesignTokens.Spacing.xxs)
                    }
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                    .stroke(isSelected ? palette.accent.opacity(0.4) : .clear, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title) script")
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityHint(isSelected ? "Double tap to deselect" : "Double tap to select")
    }
}
