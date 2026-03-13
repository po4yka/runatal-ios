//
//  OnboardingAtmosphereOption.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
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
        self.selectedScript == self.script
    }

    private var runicSample: String {
        RunicTransliterator.transliterate(self.sampleLatin, to: self.script)
    }

    private var recommendedFont: RunicFont {
        RunicFontConfiguration.recommendedFont(for: self.script)
    }

    var body: some View {
        Button {
            self.onSelect(self.isSelected ? nil : self.script)
        } label: {
            ContentPlate(
                palette: self.palette,
                tone: self.isSelected ? .primary : .secondary,
                cornerRadius: DesignTokens.CornerRadius.lg,
                shadowRadius: self.isSelected ? DesignTokens.Elevation.low : 0,
                contentPadding: DesignTokens.Spacing.md,
            ) {
                HStack(spacing: DesignTokens.Spacing.sm) {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                        HStack {
                            Text(self.title)
                                .font(.headline)
                                .foregroundStyle(self.palette.textPrimary)

                            Spacer()

                            if self.isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.body)
                                    .foregroundStyle(self.palette.accent)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }

                        Text(self.subtitle)
                            .font(DesignTokens.Typography.listMeta)
                            .foregroundStyle(self.palette.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(self.runicSample)
                            .runicTextStyle(
                                script: self.script,
                                font: self.recommendedFont,
                                style: .subheadline,
                                minSize: 14,
                                maxSize: 20,
                            )
                            .foregroundStyle(self.palette.runeText)
                            .lineLimit(1)
                            .padding(.top, DesignTokens.Spacing.xxs)
                    }
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                    .stroke(self.isSelected ? self.palette.accent.opacity(0.4) : self.palette.contentStroke.opacity(0.45), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(self.title) script")
        .accessibilityValue(self.isSelected ? "Selected" : "Not selected")
        .accessibilityHint(self.isSelected ? "Double tap to deselect" : "Double tap to select")
    }
}
