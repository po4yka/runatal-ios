//
//  SettingsNavigationLinksSectionView.swift
//  RunicQuotes
//
//  Created by Codex on 2026-03-13.
//

import SwiftUI

struct SettingsNavigationLinksSectionView: View {
    let palette: AppThemePalette

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            NavigationLink {
                RuneReferenceView()
            } label: {
                linkCard(
                    title: "Rune Reference",
                    icon: "character.book.closed"
                )
            }
            .buttonStyle(.plain)

            NavigationLink {
                ArchiveView()
            } label: {
                linkCard(title: "Archive", icon: "archivebox")
            }
            .buttonStyle(.plain)
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
