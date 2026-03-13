//
//  CollectionShelfRow.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
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
        @ViewBuilder trailing: () -> Trailing,
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
            self.leading

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                if let eyebrow {
                    SectionLabel(title: eyebrow, palette: self.palette)
                }

                Text(self.title)
                    .font(DesignTokens.Typography.cardTitle)
                    .foregroundStyle(self.palette.textPrimary)

                Text(self.subtitle)
                    .font(DesignTokens.Typography.supportingBody)
                    .foregroundStyle(self.palette.textSecondary)
                    .lineLimit(2)

                if let supporting, !supporting.isEmpty {
                    Text(supporting)
                        .font(DesignTokens.Typography.listMeta)
                        .foregroundStyle(self.palette.textTertiary)
                        .lineLimit(2)
                }

                if !self.meta.isEmpty {
                    MetaRow(items: self.meta, palette: self.palette)
                }
            }

            Spacer(minLength: DesignTokens.Spacing.sm)
            self.trailing
        }
        .padding(DesignTokens.Spacing.md)
        .background {
            RoundedRectangle(
                cornerRadius: DesignTokens.CornerRadius.xl,
                style: .continuous,
            )
            .fill(self.palette.rowFill)
        }
        .overlay {
            RoundedRectangle(
                cornerRadius: DesignTokens.CornerRadius.xl,
                style: .continuous,
            )
            .strokeBorder(
                self.palette.contentStroke.opacity(0.85),
                lineWidth: DesignTokens.Stroke.hairline,
            )
        }
    }
}
