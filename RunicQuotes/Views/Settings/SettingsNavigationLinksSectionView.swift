//
//  SettingsNavigationLinksSectionView.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
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
                self.linkCard(
                    title: String(localized: "translation.link.title"),
                    icon: "character.cursor.ibeam",
                )
            }
            .accessibilityIdentifier("settings_translation_link")

            NavigationLink(value: SettingsDestination.runeReference) {
                self.linkCard(
                    title: "Rune Reference",
                    icon: "character.book.closed",
                )
            }

            NavigationLink(value: SettingsDestination.archive) {
                self.linkCard(title: "Archive", icon: "archivebox")
            }
        }
    }

    private func linkCard(title: String, icon: String) -> some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(self.palette.accent)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(self.palette.textPrimary)

                if let description = description(for: title) {
                    Text(description)
                        .font(DesignTokens.Typography.listMeta)
                        .foregroundStyle(self.palette.textSecondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(self.palette.textTertiary)
        }
    }

    private func description(for title: String) -> String? {
        switch title {
        case String(localized: "translation.link.title"):
            "Direct transliteration or historical rendering"
        case "Rune Reference":
            "Script forms, meanings, and historical notes"
        case "Archive":
            "Hidden and deleted passages"
        default:
            nil
        }
    }
}
