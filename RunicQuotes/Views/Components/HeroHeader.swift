//
//  HeroHeader.swift
//  RunicQuotes
//
//  Created by Codex on 2026-03-13.
//

import SwiftUI

struct HeroHeader: View {
    let eyebrow: String?
    let title: String
    let subtitle: String
    let meta: [String]
    let palette: AppThemePalette
    let alignment: HorizontalAlignment

    init(
        eyebrow: String? = nil,
        title: String,
        subtitle: String,
        meta: [String] = [],
        palette: AppThemePalette,
        alignment: HorizontalAlignment = .leading
    ) {
        self.eyebrow = eyebrow
        self.title = title
        self.subtitle = subtitle
        self.meta = meta
        self.palette = palette
        self.alignment = alignment
    }

    var body: some View {
        VStack(alignment: alignment, spacing: DesignTokens.Spacing.xs) {
            if let eyebrow, !eyebrow.isEmpty {
                SectionLabel(title: eyebrow, palette: palette)
            }

            Text(title)
                .font(DesignTokens.Typography.hero)
                .foregroundStyle(palette.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text(subtitle)
                .font(DesignTokens.Typography.callout)
                .foregroundStyle(palette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            if !meta.isEmpty {
                MetaRow(items: meta, palette: palette)
                    .padding(.top, DesignTokens.Spacing.xxs)
            }
        }
        .frame(maxWidth: .infinity, alignment: alignment == .leading ? .leading : .center)
    }
}
