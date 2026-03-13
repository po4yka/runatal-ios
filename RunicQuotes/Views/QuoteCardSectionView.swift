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
    let latinText: String
    let author: String
    let script: RunicScript
    let font: RunicFont
    let decorativeGlyph: String
    let palette: AppThemePalette
    let isScriptMorphing: Bool
    let onShowActions: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appearScale = 1.0
    @State private var appearOpacity = 1.0

    var body: some View {
        GlassCard(intensity: .strong) {
            VStack(spacing: 0) {
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
                    .frame(maxWidth: .infinity, minHeight: 220, alignment: .center)
                    .padding(.horizontal, DesignTokens.Spacing.sm)
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
                                palette.separator.opacity(0.5),
                                palette.separator.opacity(0.7),
                                palette.separator.opacity(0.5),
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
                    .font(.body)
                    .foregroundStyle(palette.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
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
                        .font(.callout)
                        .foregroundStyle(palette.textTertiary)
                        .italic()
                        .accessibilityLabel("Author")
                        .accessibilityValue(author)
                        .accessibilityIdentifier("authorText")

                    Spacer()
                }
                .padding(.horizontal, DesignTokens.Spacing.md)
                .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
                .background(palette.surface)
            }
            .frame(maxWidth: .infinity, minHeight: 360, alignment: .top)
            .overlay(alignment: .topTrailing) {
                Text(decorativeGlyph)
                    .font(.system(size: 60))
                    .foregroundStyle(palette.textPrimary)
                    .opacity(0.03)
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
        .onLongPressGesture {
            onShowActions()
        }
    }
}
