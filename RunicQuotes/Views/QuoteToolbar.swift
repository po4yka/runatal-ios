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
    let openCreateChoices: () -> Void

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

            Button(action: self.openCreateChoices) {
                Label("Create quote", systemImage: "plus")
                    .labelStyle(.iconOnly)
                    .symbolRenderingMode(.monochrome)
            }
            .foregroundStyle(self.palette.textPrimary)
            .accessibilityIdentifier("quote_create_menu")
        }
    }
}
