//
//  HomeBottomAccessoryView.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import SwiftUI

struct HomeBottomAccessoryView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.runicTheme) private var runicTheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @EnvironmentObject private var controller: HomeAccessoryController

    let onNextQuote: () -> Void

    private var palette: AppThemePalette {
        .themed(self.runicTheme, for: self.colorScheme)
    }

    var body: some View {
        LiquidCard(
            palette: self.palette,
            role: .chrome,
            cornerRadius: DesignTokens.CornerRadius.xxl,
            shadowRadius: DesignTokens.Elevation.chrome,
            contentPadding: DesignTokens.Spacing.sm,
            interactive: true,
        ) {
            if self.dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    self.context
                    self.nextButton
                }
            } else {
                HStack(spacing: DesignTokens.Spacing.sm) {
                    self.context
                    Spacer(minLength: DesignTokens.Spacing.xs)
                    self.nextButton
                }
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("home_accessory")
    }

    private var context: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
            Text(self.controller.collectionName)
                .font(DesignTokens.Typography.toolbarLabel)
                .foregroundStyle(self.palette.textPrimary)
                .lineLimit(self.dynamicTypeSize.isAccessibilitySize ? nil : 1)
                .fixedSize(horizontal: false, vertical: self.dynamicTypeSize.isAccessibilitySize)
                .accessibilityIdentifier("home_accessory_collection")

            Text("\(self.controller.scriptName) · \(self.controller.caption)")
                .font(DesignTokens.Typography.listMeta)
                .foregroundStyle(self.palette.textTertiary)
                .lineLimit(self.dynamicTypeSize.isAccessibilitySize ? nil : 1)
                .fixedSize(horizontal: false, vertical: self.dynamicTypeSize.isAccessibilitySize)
                .accessibilityIdentifier("home_accessory_context")
        }
    }

    private var nextButton: some View {
        Button(action: self.onNextQuote) {
            if self.dynamicTypeSize.isAccessibilitySize {
                Text("Next Quote")
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)
            } else {
                Label("Next Quote", systemImage: "sparkles")
            }
        }
        .buttonStyle(LiquidProminentButtonStyle(palette: self.palette, emphasized: true))
        .accessibilityLabel("Next Quote")
        .accessibilityIdentifier("home_accessory_next_quote")
    }
}
