//
//  QuoteToolbar.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
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
            Text(self.currentCollection.displayName)
                .font(DesignTokens.Typography.toolbarLabel)
                .foregroundStyle(self.palette.textTertiary)
        }

        ToolbarItemGroup(placement: .primaryAction) {
            NavigationLink {
                NotificationCenterView()
            } label: {
                Label("Notifications", systemImage: "bell")
                    .labelStyle(.iconOnly)
                    .symbolRenderingMode(.monochrome)
            }
            .foregroundStyle(self.palette.textPrimary)
            .accessibilityIdentifier("quote_notifications_button")

            Menu {
                Button(String(localized: "translation.menu.newQuote"), systemImage: "plus", action: self.createQuote)
                    .accessibilityLabel(String(localized: "translation.menu.newQuote"))
                    .accessibilityIdentifier("quote_create_new_action")

                Button(String(localized: "translation.menu.translate"), systemImage: "character.cursor.ibeam", action: self.openTranslation)
                    .accessibilityLabel(String(localized: "translation.menu.translate"))
                    .accessibilityIdentifier("quote_create_translate_action")
            } label: {
                Label("Create quote", systemImage: "plus")
                    .labelStyle(.iconOnly)
                    .symbolRenderingMode(.monochrome)
            }
            .foregroundStyle(self.palette.textPrimary)
            .accessibilityIdentifier("quote_create_menu")
        }
    }
}
