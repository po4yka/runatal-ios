//
//  QuoteCardSectionView.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import SwiftUI
import TipKit

/// Main quote presentation card used on the home screen.
struct QuoteCardSectionView: View {
    private static let shouldMirrorHomeTipsInlineForTesting =
        ProcessInfo.processInfo.environment["TIPKIT_UI_INLINE_MIRRORS"] == "1"

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
    let tipRefreshID: UUID
    let onNextQuote: () -> Void
    let onToggleSave: () -> Void
    let onShowActions: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var featureDiscoveryController: FeatureDiscoveryController
    @State private var appearScale = 1.0
    @State private var appearOpacity = 1.0

    var body: some View {
        ContentPlate(
            palette: self.palette,
            tone: .hero,
            cornerRadius: DesignTokens.CornerRadius.xxl,
            shadowRadius: DesignTokens.Elevation.hero,
            contentPadding: DesignTokens.Spacing.lg,
        ) {
            VStack(spacing: 0) {
                self.header

                Text(self.runicText)
                    .runicTextStyle(
                        script: self.script,
                        font: self.font,
                        style: .title,
                        minSize: 28,
                        maxSize: 56,
                    )
                    .foregroundStyle(self.palette.runeText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(10)
                    .frame(maxWidth: .infinity, minHeight: 200, alignment: .center)
                    .padding(.horizontal, DesignTokens.Spacing.xs)
                    .padding(.top, DesignTokens.Spacing.xs)
                    .padding(.bottom, DesignTokens.Spacing.lg)
                    .opacity(self.isScriptMorphing ? 0.2 : 1.0)
                    .blur(radius: self.isScriptMorphing ? 7 : 0)
                    .scaleEffect(self.isScriptMorphing ? 0.98 : 1.0)
                    .contentTransition(.opacity)
                    .accessibilityLabel("Runic text")
                    .accessibilityValue(self.runicText)
                    .accessibilityHint("The quote displayed in \(self.script.rawValue)")

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                .clear,
                                self.palette.separator.opacity(0.35),
                                self.palette.accent.opacity(0.32),
                                self.palette.separator.opacity(0.35),
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1)
                    .padding(.horizontal, DesignTokens.Spacing.xs)
                    .accessibilityHidden(true)

                Text(self.latinText)
                    .font(DesignTokens.Typography.sectionTitle)
                    .foregroundStyle(self.palette.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(.horizontal, DesignTokens.Spacing.md)
                    .padding(.top, DesignTokens.Spacing.md)
                    .padding(.bottom, DesignTokens.Spacing.sm)
                    .opacity(self.isScriptMorphing ? 0.65 : 1.0)
                    .contentTransition(.opacity)
                    .accessibilityLabel("Quote")
                    .accessibilityValue(self.latinText)
                    .accessibilityIdentifier("quoteText")

                Spacer(minLength: 8)

                HStack {
                    Text("— \(self.author)")
                        .font(DesignTokens.Typography.callout)
                        .foregroundStyle(self.palette.textTertiary)
                        .italic()
                        .accessibilityLabel("Author")
                        .accessibilityValue(self.author)
                        .accessibilityIdentifier("authorText")

                    Spacer()
                }
                .padding(.top, DesignTokens.Spacing.sm)

                self.actionBar
                    .padding(.top, DesignTokens.Spacing.md)

                if Self.shouldMirrorHomeTipsInlineForTesting {
                    self.homeTestingTipMirrors
                        .padding(.top, DesignTokens.Spacing.md)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 380, alignment: .top)
            .overlay(alignment: .topTrailing) {
                Text(self.decorativeGlyph)
                    .font(.system(size: 60))
                    .foregroundStyle(self.palette.ornament)
                    .opacity(0.18)
                    .rotationEffect(.degrees(-12))
                    .padding(.top, DesignTokens.Spacing.sm)
                    .padding(.trailing, DesignTokens.Spacing.md)
                    .accessibilityHidden(true)
                    .allowsHitTesting(false)
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .scaleEffect(self.appearScale)
        .opacity(self.appearOpacity)
        .onChange(of: self.latinText) {
            guard !self.reduceMotion else { return }
            self.appearScale = 0.97
            self.appearOpacity = 0.6
            withAnimation(AnimationPresets.cardAppear) {
                self.appearScale = 1.0
                self.appearOpacity = 1.0
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("quote_card")
        .accessibilityAction(named: "More actions") {
            self.onShowActions()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            SectionLabel(title: "Current Reading", palette: self.palette)
            Text("Rendered in \(self.script.displayName)")
                .font(DesignTokens.Typography.listMeta)
                .foregroundStyle(self.palette.textTertiary)

            HStack(spacing: DesignTokens.Spacing.xs) {
                Text(self.presentationSource.disclosureTitle)
                    .font(DesignTokens.Typography.listMeta)
                    .foregroundStyle(self.palette.textSecondary)

                if let evidenceTier {
                    Text("· \(evidenceTier.displayName)")
                        .font(DesignTokens.Typography.listMeta)
                        .foregroundStyle(self.palette.textSecondary)
                }
            }

            if let primarySourceLabel {
                Text(primarySourceLabel)
                    .font(DesignTokens.Typography.listMeta)
                    .foregroundStyle(self.palette.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var actionBar: some View {
        ActionBar(palette: self.palette) {
            self.nextQuoteButton
            self.saveQuoteButton
            self.actionButton(
                title: "Actions",
                systemImage: "ellipsis.circle",
                emphasized: false,
                action: self.onShowActions,
            )
        }
    }

    @ViewBuilder
    private var homeTestingTipMirrors: some View {
        switch self.featureDiscoveryController.homeTestingSequence {
        case .hidden:
            EmptyView()
        case .nextQuote:
            self.testingTipMirror(
                title: "Cycle the reading",
                message: "Tap New Quote to pull another passage into the current script.",
                systemImage: "sparkles",
                accessibilityIdentifier: "tip_home_next_quote_inline",
            )
        case .saveQuote:
            self.testingTipMirror(
                title: "Keep the lines that matter",
                message: "Save a passage to revisit it later in your personal library.",
                systemImage: "bookmark",
                accessibilityIdentifier: "tip_home_save_quote_inline",
            )
        }
    }

    private func testingTipMirror(
        title: String,
        message: String,
        systemImage: String,
        accessibilityIdentifier: String,
    ) -> some View {
        HStack(alignment: .top, spacing: DesignTokens.Spacing.sm) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(self.palette.accent)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                Text(title)
                    .font(DesignTokens.Typography.bodyEmphasis)
                    .foregroundStyle(self.palette.textPrimary)

                Text(message)
                    .font(DesignTokens.Typography.listMeta)
                    .foregroundStyle(self.palette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(DesignTokens.Spacing.sm)
        .background {
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md, style: .continuous)
                .fill(self.palette.editorialInset)
        }
        .overlay {
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md, style: .continuous)
                .strokeBorder(self.palette.cardStroke, lineWidth: DesignTokens.Stroke.hairline)
        }
        .accessibilityIdentifier(accessibilityIdentifier)
    }

    private var nextQuoteButton: some View {
        self.actionButton(
            title: "New Quote",
            systemImage: "sparkles",
            emphasized: true,
            action: self.onNextQuote,
        )
        .popoverTip(HomeNextQuoteTip(), arrowEdge: .bottom)
        .id("home-next-quote-tip-\(self.tipRefreshID.uuidString)")
    }

    private var saveQuoteButton: some View {
        self.actionButton(
            title: self.isSaved ? "Saved" : "Save",
            systemImage: self.isSaved ? "bookmark.fill" : "bookmark",
            emphasized: false,
            action: self.onToggleSave,
        )
        .popoverTip(HomeSaveQuoteTip(), arrowEdge: .bottom)
        .id("home-save-quote-tip-\(self.tipRefreshID.uuidString)")
    }

    private func actionButton(
        title: String,
        systemImage: String,
        emphasized: Bool,
        action: @escaping () -> Void,
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(LiquidProminentButtonStyle(palette: self.palette, emphasized: emphasized))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityIdentifier(self.accessibilityID(for: title))
    }

    private func accessibilityID(for title: String) -> String {
        switch title {
        case "New Quote":
            "quote_next_button"
        case "Save", "Saved":
            "quote_save_button"
        default:
            "quote_actions_button"
        }
    }
}
