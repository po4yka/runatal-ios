//
//  HeroHeader.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
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
        alignment: HorizontalAlignment = .leading,
    ) {
        self.eyebrow = eyebrow
        self.title = title
        self.subtitle = subtitle
        self.meta = meta
        self.palette = palette
        self.alignment = alignment
    }

    var body: some View {
        VStack(alignment: self.alignment, spacing: DesignTokens.Spacing.xs) {
            if let eyebrow, !eyebrow.isEmpty {
                SectionLabel(title: eyebrow, palette: self.palette)
            }

            Text(self.title)
                .font(DesignTokens.Typography.hero)
                .foregroundStyle(self.palette.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text(self.subtitle)
                .font(DesignTokens.Typography.callout)
                .foregroundStyle(self.palette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            if !self.meta.isEmpty {
                MetaRow(items: self.meta, palette: self.palette)
                    .padding(.top, DesignTokens.Spacing.xxs)
            }
        }
        .frame(maxWidth: .infinity, alignment: self.alignment == .leading ? .leading : .center)
    }
}
