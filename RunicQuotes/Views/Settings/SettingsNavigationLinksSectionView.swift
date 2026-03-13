//
//  SettingsNavigationLinksSectionView.swift
//  RunicQuotes
//
//  Created by Codex on 2026-03-13.
//

import SwiftUI

enum SettingsDestination: Hashable {
    case translation
    case runeReference
    case archive
}

struct SettingsNavigationLinksSectionView: View {
    let palette: AppThemePalette

    var body: some View {
        Group {
            NavigationLink(value: SettingsDestination.translation) {
                linkCard(
                    title: String(localized: "translation.link.title"),
                    icon: "character.cursor.ibeam"
                )
            }
            .accessibilityIdentifier("settings_translation_link")

            NavigationLink(value: SettingsDestination.runeReference) {
                linkCard(
                    title: "Rune Reference",
                    icon: "character.book.closed"
                )
            }

            NavigationLink(value: SettingsDestination.archive) {
                linkCard(title: "Archive", icon: "archivebox")
            }
        }
    }

    private func linkCard(title: String, icon: String) -> some View {
        GlassCard(intensity: .medium) {
            HStack {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(palette.accent)

                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(palette.textPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(palette.textTertiary)
            }
        }
    }
}
