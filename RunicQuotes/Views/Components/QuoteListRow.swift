//
//  QuoteListRow.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import SwiftUI

struct QuoteListRow<Badge: View, Footer: View>: View {
    let palette: AppThemePalette
    let presentation: ResolvedRunicPresentation
    let script: RunicScript
    let font: RunicFont
    let quoteText: String
    let author: String
    let metadata: [String]
    let badge: Badge
    let footer: Footer

    init(
        palette: AppThemePalette,
        presentation: ResolvedRunicPresentation,
        script: RunicScript,
        font: RunicFont,
        quoteText: String,
        author: String,
        metadata: [String] = [],
        @ViewBuilder badge: () -> Badge,
        @ViewBuilder footer: () -> Footer,
    ) {
        self.palette = palette
        self.presentation = presentation
        self.script = script
        self.font = font
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
                    if self.presentation.isRenderable, !self.presentation.text.isEmpty {
                        Text(self.presentation.text)
                            .runicTextStyle(script: self.script, font: self.font, style: .caption, minSize: 12, maxSize: 16)
                            .foregroundStyle(self.palette.runeText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }

                    Text(self.presentation.source.shareDisclosureTitle)
                        .font(.caption)
                        .foregroundStyle(self.palette.textSecondary)
                    if !self.presentation.warnings.isEmpty {
                        Text(self.presentation.warnings.joined(separator: " "))
                            .font(.caption)
                            .foregroundStyle(self.palette.textSecondary)
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
