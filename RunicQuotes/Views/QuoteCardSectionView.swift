//
//  QuoteCardSectionView.swift
//  RunicQuotes
//
//  Created by Claude on 2026-03-13.
//

import SwiftUI

/// Main quote presentation card used on the home screen.
struct QuoteCardSectionView: View {
    let runicText: String
    let presentationSource: RunicPresentationSource
    let evidenceTier: TranslationEvidenceTier?
    let primarySourceLabel: String?
    let latinText: String
    let author: String
    let script: RunicScript
    let font: RunicFont
    let decorativeGlyph: String
    let palette: AppThemePalette
    let isScriptMorphing: Bool
    let isSaved: Bool
    let onNextQuote: () -> Void
    let onToggleSave: () -> Void
    let onShowActions: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appearScale = 1.0
    @State private var appearOpacity = 1.0

    var body: some View {
        ContentPlate(
            palette: palette,
            tone: .hero,
            cornerRadius: DesignTokens.CornerRadius.xxl,
            shadowRadius: DesignTokens.Elevation.hero,
            contentPadding: DesignTokens.Spacing.lg
        ) {
            VStack(spacing: 0) {
                header

                Text(runicText)
                    .runicTextStyle(
                        script: script,
                        font: font,
                        style: .title,
                        minSize: 28,
                        maxSize: 56
                    )
                    .foregroundStyle(palette.runeText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(10)
                    .frame(maxWidth: .infinity, minHeight: 200, alignment: .center)
                    .padding(.horizontal, DesignTokens.Spacing.xs)
                    .padding(.top, DesignTokens.Spacing.xs)
                    .padding(.bottom, DesignTokens.Spacing.lg)
                    .opacity(isScriptMorphing ? 0.2 : 1.0)
                    .blur(radius: isScriptMorphing ? 7 : 0)
                    .scaleEffect(isScriptMorphing ? 0.98 : 1.0)
                    .contentTransition(.opacity)
                    .accessibilityLabel("Runic text")
                    .accessibilityValue(runicText)
                    .accessibilityHint("The quote displayed in \(script.rawValue)")

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                .clear,
                                palette.separator.opacity(0.35),
                                palette.accent.opacity(0.55),
                                palette.separator.opacity(0.35),
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1.5)
                    .padding(.horizontal, DesignTokens.Spacing.xs)
                    .accessibilityHidden(true)

                Text(latinText)
                    .font(DesignTokens.Typography.sectionTitle)
                    .foregroundStyle(palette.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(.horizontal, DesignTokens.Spacing.md)
                    .padding(.top, DesignTokens.Spacing.md)
                    .padding(.bottom, DesignTokens.Spacing.sm)
                    .opacity(isScriptMorphing ? 0.65 : 1.0)
                    .contentTransition(.opacity)
                    .accessibilityLabel("Quote")
                    .accessibilityValue(latinText)
                    .accessibilityIdentifier("quoteText")

                Spacer(minLength: 8)

                HStack {
                    Text("— \(author)")
                        .font(DesignTokens.Typography.callout)
                        .foregroundStyle(palette.textTertiary)
                        .italic()
                        .accessibilityLabel("Author")
                        .accessibilityValue(author)
                        .accessibilityIdentifier("authorText")

                    Spacer()
                }
                    .padding(.top, DesignTokens.Spacing.sm)

                actionBar
                    .padding(.top, DesignTokens.Spacing.md)
            }
            .frame(maxWidth: .infinity, minHeight: 380, alignment: .top)
            .overlay(alignment: .topTrailing) {
                Text(decorativeGlyph)
                    .font(.system(size: 60))
                    .foregroundStyle(palette.ornament)
                    .opacity(0.32)
                    .rotationEffect(.degrees(-12))
                    .padding(.top, DesignTokens.Spacing.sm)
                    .padding(.trailing, DesignTokens.Spacing.md)
                    .accessibilityHidden(true)
                    .allowsHitTesting(false)
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .scaleEffect(appearScale)
        .opacity(appearOpacity)
        .onChange(of: latinText) {
            guard !reduceMotion else { return }
            appearScale = 0.97
            appearOpacity = 0.6
            withAnimation(AnimationPresets.cardAppear) {
                appearScale = 1.0
                appearOpacity = 1.0
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("quote_card")
        .accessibilityAction(named: "More actions") {
            onShowActions()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            SectionLabel(title: "Current Reading", palette: palette)
            Text("Rendered in \(script.displayName)")
                .font(DesignTokens.Typography.metadata)
                .foregroundStyle(palette.textTertiary)

            HStack(spacing: DesignTokens.Spacing.xs) {
                Text(presentationSource.disclosureTitle)
                    .font(DesignTokens.Typography.metadata)
                    .foregroundStyle(palette.textSecondary)

                if let evidenceTier {
                    Text("· \(evidenceTier.displayName)")
                        .font(DesignTokens.Typography.metadata)
                        .foregroundStyle(palette.textSecondary)
                }
            }

            if let primarySourceLabel {
                Text(primarySourceLabel)
                    .font(DesignTokens.Typography.metadata)
                    .foregroundStyle(palette.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var actionBar: some View {
        ActionBar(palette: palette) {
            actionButton(
                title: "New Quote",
                systemImage: "sparkles",
                emphasized: true,
                action: onNextQuote
            )
            actionButton(
                title: isSaved ? "Saved" : "Save",
                systemImage: isSaved ? "bookmark.fill" : "bookmark",
                emphasized: false,
                action: onToggleSave
            )
            actionButton(
                title: "Actions",
                systemImage: "ellipsis.circle",
                emphasized: false,
                action: onShowActions
            )
        }
    }

    private func actionButton(
        title: String,
        systemImage: String,
        emphasized: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(LiquidProminentButtonStyle(palette: palette, emphasized: emphasized))
        .accessibilityIdentifier(accessibilityID(for: title))
    }

    private func accessibilityID(for title: String) -> String {
        switch title {
        case "New Quote":
            return "quote_next_button"
        case "Save", "Saved":
            return "quote_save_button"
        default:
            return "quote_actions_button"
        }
    }
}
