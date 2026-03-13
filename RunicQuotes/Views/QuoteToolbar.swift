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
    let openTranslation: () -> Void

    var body: some ToolbarContent {
        ToolbarItem(placement: .navigation) {
            Text(currentCollection.displayName)
                .font(DesignTokens.Typography.toolbarLabel)
                .foregroundStyle(palette.textTertiary)
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

            Menu {
                Button(action: createQuote) {
                    Label(String(localized: "translation.menu.newQuote"), systemImage: "plus")
                }

                Button(action: openTranslation) {
                    Label(String(localized: "translation.menu.translate"), systemImage: "character.cursor.ibeam")
                }
            } label: {
                Label("Create quote", systemImage: "plus")
                    .labelStyle(.iconOnly)
                    .symbolRenderingMode(.monochrome)
            }
            .foregroundStyle(palette.textPrimary)
            .accessibilityIdentifier("quote_create_menu")
        }
    }
}
