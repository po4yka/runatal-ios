//
//  QuoteToolbar.swift
//  RunicQuotes
//
//  Created by Claude on 2026-03-13.
//

import SwiftUI

/// Toolbar content for the quote screen.
struct QuoteToolbar: ToolbarContent {
    let currentCollection: QuoteCollection
    let palette: AppThemePalette
    let createQuote: () -> Void

    var body: some ToolbarContent {
        ToolbarItem(placement: .navigation) {
            Text(currentCollection.displayName)
                .font(DesignTokens.Typography.metadata)
                .foregroundStyle(palette.textTertiary)
                .padding(.horizontal, DesignTokens.Spacing.sm)
                .padding(.vertical, DesignTokens.Spacing.xs)
                .background {
                    Capsule()
                        .fill(palette.bannerBackground)
                }
                .overlay {
                    Capsule()
                        .strokeBorder(
                            palette.cardStroke,
                            lineWidth: DesignTokens.Stroke.hairline
                        )
                }
        }

        ToolbarItemGroup(placement: .primaryAction) {
            NavigationLink {
                NotificationCenterView()
            } label: {
                Label("Notifications", systemImage: "bell")
                    .labelStyle(.iconOnly)
                    .symbolRenderingMode(.monochrome)
            }
            .foregroundStyle(palette.textPrimary)
            .accessibilityIdentifier("quote_notifications_button")

            Button(action: createQuote) {
                Label("Create quote", systemImage: "plus")
                    .labelStyle(.iconOnly)
                    .symbolRenderingMode(.monochrome)
            }
            .foregroundStyle(palette.textPrimary)
            .accessibilityIdentifier("quote_create_button")
        }
    }
}
