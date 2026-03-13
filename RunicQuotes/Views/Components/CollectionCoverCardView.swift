//
//  CollectionCoverCardView.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import SwiftUI

struct CollectionCoverCardView: View {
    let cover: QuoteCollectionCover
    let isSelected: Bool
    let script: RunicScript
    let font: RunicFont
    let palette: AppThemePalette
    let onSelect: (QuoteCollection) -> Void

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        Button {
            self.onSelect(self.cover.collection)
        } label: {
            self.cardBody
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("collection_cover_\(self.cover.collection.rawValue)")
        .accessibilityLabel("\(self.cover.collection.displayName) collection")
        .accessibilityValue(self.isSelected ? "Selected" : "Not selected")
        .accessibilityHint("Double tap to browse \(self.cover.collection.displayName) quotes")
    }

    private var cardBody: some View {
        self.cardContent
            .padding(DesignTokens.Spacing.md)
            .frame(width: 230, alignment: .leading)
            .frame(minHeight: 210, alignment: .leading)
            .background(self.cardBackground)
            .overlay(alignment: .topLeading) {
                self.topAccent
            }
            .overlay(self.cardBorder)
            .opacity(self.isSelected ? 1.0 : 0.88)
            .shadow(
                color: self.palette.shadowColor.opacity(self.isSelected ? 1 : 0.7),
                radius: self.isSelected ? DesignTokens.Elevation.medium : DesignTokens.Elevation.low,
                x: 0,
                y: self.isSelected ? 8 : 4,
            )
            .scaleEffect(self.isSelected ? 1 : 0.985)
            .animation(DesignTokens.Motion.reveal, value: self.isSelected)
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 9) {
            self.collectionMetadata
            self.runicPreview
            self.latinPreview
            self.collectionTitle
            self.collectionSubtitle
            self.authorPreview
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xl)
            .fill(self.cardBackgroundColor)
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xl)
            .stroke(
                self.isSelected ? self.palette.strongCardStroke : self.palette.cardStroke,
                lineWidth: self.isSelected ? DesignTokens.Stroke.emphasis : DesignTokens.Stroke.hairline,
            )
    }

    private var topAccent: some View {
        Capsule()
            .fill(
                LinearGradient(
                    colors: self.gradientColors,
                    startPoint: .leading,
                    endPoint: .trailing,
                ),
            )
            .frame(width: self.isSelected ? 88 : 58, height: 4)
            .padding(.top, DesignTokens.Spacing.sm)
            .padding(.leading, DesignTokens.Spacing.md)
    }

    private var collectionMetadata: some View {
        HStack(alignment: .top) {
            Label(self.cover.collection.displayName, systemImage: self.cover.collection.systemImage)
                .font(DesignTokens.Typography.label)
                .foregroundStyle(self.palette.textPrimary)
                .labelStyle(.titleAndIcon)

            Spacer(minLength: 8)

            Text("\(self.cover.quoteCount)")
                .font(DesignTokens.Typography.metadata)
                .foregroundStyle(self.palette.textPrimary)
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background {
                    Capsule()
                        .fill(self.isSelected ? self.palette.chipSelectedFill : self.palette.bannerBackground)
                }
        }
    }

    private var runicPreview: some View {
        Text(self.cover.runicPreview)
            .runicTextStyle(
                script: self.script,
                font: self.font,
                style: .body,
                minSize: 18,
                maxSize: 30,
            )
            .foregroundStyle(self.palette.runeText)
            .lineLimit(2)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .topLeading)
    }

    private var latinPreview: some View {
        Text(self.cover.latinPreview)
            .font(DesignTokens.Typography.label)
            .foregroundStyle(self.palette.textSecondary)
            .lineLimit(2)
    }

    private var collectionTitle: some View {
        Text(self.cover.collection.displayName)
            .font(DesignTokens.Typography.cardTitle)
            .foregroundStyle(self.palette.textPrimary)
    }

    private var collectionSubtitle: some View {
        Text(self.cover.collection.subtitle)
            .font(DesignTokens.Typography.callout)
            .foregroundStyle(self.palette.textSecondary)
            .lineLimit(2)
    }

    private var authorPreview: some View {
        Text("— \(self.cover.authorPreview)")
            .font(DesignTokens.Typography.label)
            .foregroundStyle(self.palette.textTertiary)
            .lineLimit(1)
    }

    private var cardBackgroundColor: Color {
        self.reduceTransparency
            ? self.palette.editorialSurface
            : (self.isSelected ? self.palette.editorialSurface : self.palette.editorialInset)
    }

    private var gradientColors: [Color] {
        let alpha = self.isSelected ? 1.0 : 0.85

        switch self.cover.collection {
        case .all:
            return [
                self.palette.accent.opacity(0.35 * alpha),
                self.palette.accentSecondary.opacity(0.72 * alpha),
            ]
        case .motivation:
            return [
                self.palette.warning.opacity(0.65 * alpha),
                self.palette.accent.opacity(0.72 * alpha),
            ]
        case .stoic:
            return [
                self.palette.textSecondary.opacity(0.6 * alpha),
                self.palette.textTertiary.opacity(0.7 * alpha),
            ]
        case .tolkien:
            return [
                self.palette.success.opacity(0.62 * alpha),
                self.palette.accentSecondary.opacity(0.7 * alpha),
            ]
        }
    }
}
