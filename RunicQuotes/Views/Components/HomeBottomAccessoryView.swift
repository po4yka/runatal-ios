//
//  HomeBottomAccessoryView.swift
//  RunicQuotes
//
//  Created by Codex on 2026-03-13.
//

import SwiftUI

struct HomeBottomAccessoryView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.runicTheme) private var runicTheme
    @Environment(\.tabViewBottomAccessoryPlacement) private var placement
    @EnvironmentObject private var controller: HomeAccessoryController

    let onNextQuote: () -> Void

    private var palette: AppThemePalette {
        .themed(runicTheme, for: colorScheme)
    }

    private var isInline: Bool {
        placement == .inline
    }

    var body: some View {
        LiquidCard(
            palette: palette,
            role: .chrome,
            cornerRadius: DesignTokens.CornerRadius.xxl,
            shadowRadius: DesignTokens.Elevation.chrome,
            contentPadding: isInline ? DesignTokens.Spacing.xs : DesignTokens.Spacing.sm,
            interactive: true
        ) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                    Text(controller.collectionName)
                        .font(DesignTokens.Typography.toolbarLabel)
                        .foregroundStyle(palette.textPrimary)
                        .lineLimit(1)

                    if !isInline {
                        Text("\(controller.scriptName) · \(controller.caption)")
                            .font(DesignTokens.Typography.listMeta)
                            .foregroundStyle(palette.textTertiary)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: DesignTokens.Spacing.xs)

                Button {
                    onNextQuote()
                } label: {
                    Label(isInline ? "Next" : "Next Quote", systemImage: "sparkles")
                }
                .buttonStyle(LiquidProminentButtonStyle(palette: palette, emphasized: true))
            }
        }
        .padding(.horizontal, isInline ? DesignTokens.Spacing.sm : DesignTokens.Spacing.md)
    }
}
