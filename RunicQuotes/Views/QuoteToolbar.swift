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
    let isCurrentQuoteSaved: Bool
    let createQuote: () -> Void
    let nextQuote: () -> Void
    let toggleSave: () -> Void
    let showActions: () -> Void

    var body: some ToolbarContent {
        ToolbarItem(placement: .navigation) {
            Text(currentCollection.displayName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(palette.textTertiary)
                .padding(.horizontal, DesignTokens.Spacing.xs)
                .padding(.vertical, DesignTokens.Spacing.xxs + 1)
                .background {
                    Capsule()
                        .fill(.ultraThinMaterial)
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
            .accessibilityIdentifier("quote_notifications_button")

            Button(action: createQuote) {
                Label("Create quote", systemImage: "plus")
                    .labelStyle(.iconOnly)
                    .symbolRenderingMode(.monochrome)
            }
            .accessibilityIdentifier("quote_create_button")

            Button(action: nextQuote) {
                Label("New quote", systemImage: "sparkles")
                    .labelStyle(.iconOnly)
                    .symbolRenderingMode(.monochrome)
            }
            .accessibilityHint("Double tap to load a new random quote")
            .accessibilityIdentifier("quote_next_button")

            Button(action: toggleSave) {
                Label(
                    isCurrentQuoteSaved ? "Unsave quote" : "Save quote",
                    systemImage: isCurrentQuoteSaved ? "bookmark.fill" : "bookmark"
                )
                .labelStyle(.iconOnly)
                .symbolRenderingMode(.monochrome)
                .symbolEffect(.bounce, value: isCurrentQuoteSaved)
            }
            .accessibilityIdentifier("quote_save_button")

            Button(action: showActions) {
                Label("More actions", systemImage: "ellipsis.circle")
                    .labelStyle(.iconOnly)
                    .symbolRenderingMode(.monochrome)
            }
            .accessibilityIdentifier("quote_actions_button")
        }
    }
}
