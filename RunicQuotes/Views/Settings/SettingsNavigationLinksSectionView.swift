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
        HStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(palette.accent)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(palette.textPrimary)

                if let description = description(for: title) {
                    Text(description)
                        .font(DesignTokens.Typography.metadata)
                        .foregroundStyle(palette.textSecondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(palette.textTertiary)
        }
    }

    private func description(for title: String) -> String? {
        switch title {
        case String(localized: "translation.link.title"):
            return "Direct transliteration or historical rendering"
        case "Rune Reference":
            return "Script forms, meanings, and historical notes"
        case "Archive":
            return "Hidden and deleted passages"
        default:
            return nil
        }
    }
}
