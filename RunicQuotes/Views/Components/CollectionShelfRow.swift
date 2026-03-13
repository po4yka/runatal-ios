//
//  CollectionShelfRow.swift
//  RunicQuotes
//
//  Created by Codex on 2026-03-13.
//

import SwiftUI

struct CollectionShelfRow<Leading: View, Trailing: View>: View {
    let palette: AppThemePalette
    let eyebrow: String?
    let title: String
    let subtitle: String
    let supporting: String?
    let meta: [String]
    let leading: Leading
    let trailing: Trailing

    init(
        palette: AppThemePalette,
        eyebrow: String? = nil,
        title: String,
        subtitle: String,
        supporting: String? = nil,
        meta: [String] = [],
        @ViewBuilder leading: () -> Leading,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.palette = palette
        self.eyebrow = eyebrow
        self.title = title
        self.subtitle = subtitle
        self.supporting = supporting
        self.meta = meta
        self.leading = leading()
        self.trailing = trailing()
    }

    var body: some View {
        HStack(alignment: .top, spacing: DesignTokens.Spacing.md) {
            leading

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                if let eyebrow {
                    SectionLabel(title: eyebrow, palette: palette)
                }

                Text(title)
                    .font(DesignTokens.Typography.cardTitle)
                    .foregroundStyle(palette.textPrimary)

                Text(subtitle)
                    .font(DesignTokens.Typography.supportingBody)
                    .foregroundStyle(palette.textSecondary)
                    .lineLimit(2)

                if let supporting, !supporting.isEmpty {
                    Text(supporting)
                        .font(DesignTokens.Typography.listMeta)
                        .foregroundStyle(palette.textTertiary)
                        .lineLimit(2)
                }

                if !meta.isEmpty {
                    MetaRow(items: meta, palette: palette)
                }
            }

            Spacer(minLength: DesignTokens.Spacing.sm)
            trailing
        }
        .padding(DesignTokens.Spacing.md)
        .background {
            RoundedRectangle(
                cornerRadius: DesignTokens.CornerRadius.xl,
                style: .continuous
            )
            .fill(palette.rowFill)
        }
        .overlay {
            RoundedRectangle(
                cornerRadius: DesignTokens.CornerRadius.xl,
                style: .continuous
            )
            .strokeBorder(
                palette.contentStroke.opacity(0.85),
                lineWidth: DesignTokens.Stroke.hairline
            )
        }
    }
}
