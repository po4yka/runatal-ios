//
//  QuoteListRow.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import SwiftUI

struct QuoteListRow<Badge: View, Footer: View>: View {
    let palette: AppThemePalette
    let runicSnippet: String
    let quoteText: String
    let author: String
    let metadata: [String]
    let badge: Badge
    let footer: Footer

    init(
        palette: AppThemePalette,
        runicSnippet: String,
        quoteText: String,
        author: String,
        metadata: [String] = [],
        @ViewBuilder badge: () -> Badge,
        @ViewBuilder footer: () -> Footer,
    ) {
        self.palette = palette
        self.runicSnippet = runicSnippet
        self.quoteText = quoteText
        self.author = author
        self.metadata = metadata
        self.badge = badge()
        self.footer = footer()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            HStack(alignment: .top, spacing: DesignTokens.Spacing.md) {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                    if !self.runicSnippet.isEmpty {
                        Text(self.runicSnippet)
                            .font(.system(.footnote, design: .serif).weight(.medium))
                            .foregroundStyle(self.palette.runeText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }

                    Text("“\(self.quoteText)”")
                        .font(DesignTokens.Typography.supportingBody)
                        .foregroundStyle(self.palette.textPrimary)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)

                    MetaRow(items: [self.author] + self.metadata, palette: self.palette)
                }

                if Badge.self != EmptyView.self {
                    Spacer(minLength: DesignTokens.Spacing.sm)
                    self.badge
                }
            }

            if Footer.self != EmptyView.self {
                Rectangle()
                    .fill(self.palette.separator.opacity(0.65))
                    .frame(height: DesignTokens.Stroke.hairline)

                self.footer
            }
        }
        .padding(DesignTokens.Spacing.md)
        .background {
            RoundedRectangle(
                cornerRadius: DesignTokens.CornerRadius.lg,
                style: .continuous,
            )
            .fill(self.palette.rowFill)
        }
        .overlay {
            RoundedRectangle(
                cornerRadius: DesignTokens.CornerRadius.lg,
                style: .continuous,
            )
            .strokeBorder(
                self.palette.contentStroke.opacity(0.85),
                lineWidth: DesignTokens.Stroke.hairline,
            )
        }
    }
}
