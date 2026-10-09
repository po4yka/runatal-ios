//
//  ShareCardContent.swift
//  RunicQuotes
//
//  Created by Claude on 08.10.26.
//

import SwiftUI

// MARK: - Share Card Content

/// The styled share card used for both preview and image rendering.
/// Always uses dark palette for the dark card style, white bg for light.
struct ShareCardContent: View {
    let runicText: String
    let latinText: String
    let author: String
    let script: RunicScript
    let font: RunicFont
    var warnings: [String] = []
    var isRunicRenderingAvailable = true
    let style: ShareCardStyle
    let presentationSource: RunicPresentationSource
    let evidenceTier: TranslationEvidenceTier?
    let primarySourceLabel: String?

    private var cardBG: Color {
        self.style == .dark ? Color(hex: 0x0C1118) : .white
    }

    private var cardBorder: Color {
        self.style == .dark
            ? Color.white.opacity(0.06)
            : Color(hex: 0x48566A).opacity(0.12)
    }

    /// Dark card always uses dark palette colors, light card uses light palette
    private var cardPalette: AppThemePalette {
        self.style == .dark
            ? .adaptive(for: .dark)
            : .adaptive(for: .light)
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: DesignTokens.Spacing.xxl)

            // Decorative rune ornament
            self.runeOrnament
                .padding(.bottom, DesignTokens.Spacing.xl)

            // Runic text (smaller, secondary)
            Group {
                if self.isRunicRenderingAvailable {
                    Text(self.runicText)
                        .runicTextStyle(
                            script: self.script,
                            font: self.font,
                            style: .caption,
                            minSize: 11,
                            maxSize: 14,
                        )

                } else {
                    Text("Runic rendering unavailable").font(.caption)
                }
            }
            .foregroundStyle(self.cardPalette.textSecondary.opacity(0.5))
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .tracking(1.12)
            .padding(.horizontal, DesignTokens.Spacing.xl)

            if !self.warnings.isEmpty {
                Text(self.warnings.joined(separator: "\n"))
                    .font(.caption)
                    .foregroundStyle(self.cardPalette.textSecondary)
                    .padding(.horizontal, DesignTokens.Spacing.xl)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Separator
            Rectangle()
                .fill(self.cardPalette.separator.opacity(0.5))
                .frame(height: 0.5)
                .frame(maxWidth: 80)
                .padding(.vertical, DesignTokens.Spacing.md)

            // Quote text
            Text("\u{201C}\(self.latinText)\u{201D}")
                .font(.system(.body, design: .serif))
                .foregroundStyle(self.cardPalette.textPrimary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, DesignTokens.Spacing.xxl)

            // Author
            Text(self.author)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(self.cardPalette.textSecondary)
                .padding(.top, DesignTokens.Spacing.sm)

            // Dot ornament
            self.dotOrnament
                .padding(.top, DesignTokens.Spacing.lg)

            // Branding
            self.brandingLabel
                .padding(.top, DesignTokens.Spacing.lg)

            self.disclosureLabel
                .padding(.top, DesignTokens.Spacing.sm)

            Spacer()
                .frame(height: DesignTokens.Spacing.xxl)
        }
        .frame(maxWidth: .infinity)
        .background(self.cardBG)
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xl)
                .strokeBorder(self.cardBorder, lineWidth: 0.5),
        )
    }

    // MARK: - Ornaments

    private var runeOrnament: some View {
        // Decorative SVG-like ornament from Figma (three-line mark)
        HStack(spacing: 4) {
            ForEach(0 ..< 3, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 1)
                    .fill(self.cardPalette.textTertiary.opacity(0.3))
                    .frame(width: 8, height: 2)
            }
        }
    }

    private var dotOrnament: some View {
        HStack(spacing: 4) {
            ForEach(0 ..< 3, id: \.self) { _ in
                Circle()
                    .fill(self.cardPalette.textTertiary.opacity(0.12))
                    .frame(width: 3, height: 3)
            }
        }
    }

    private var brandingLabel: some View {
        HStack(spacing: DesignTokens.Spacing.xs) {
            Text("\u{16B1}")
                .font(.system(size: 8))
                .foregroundStyle(self.cardPalette.textTertiary)
            Text("Runic Quotes")
                .font(.system(size: 10))
                .foregroundStyle(self.cardPalette.textTertiary)
        }
    }

    private var disclosureLabel: some View {
        VStack(spacing: 2) {
            Text(self.presentationSource.shareDisclosureTitle)
                .font(.system(size: 9))
                .foregroundStyle(self.cardPalette.textTertiary)

            if let evidenceTier {
                Text(self.presentationSource.evidenceLabel(evidenceTier))
                    .font(.system(size: 9))
                    .foregroundStyle(self.cardPalette.textTertiary.opacity(0.9))
            } else if let primarySourceLabel {
                Text(primarySourceLabel)
                    .font(.system(size: 9))
                    .foregroundStyle(self.cardPalette.textTertiary.opacity(0.9))
                    .lineLimit(1)
            }
        }
    }
}
