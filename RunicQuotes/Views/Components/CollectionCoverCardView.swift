//
//  CollectionCoverCardView.swift
//  RunicQuotes
//
//  Created by Codex on 2026-03-13.
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
            onSelect(cover.collection)
        } label: {
            cardBody
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("collection_cover_\(cover.collection.rawValue)")
        .accessibilityLabel("\(cover.collection.displayName) collection")
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityHint("Double tap to browse \(cover.collection.displayName) quotes")
    }

    private var cardBody: some View {
        cardContent
            .padding(DesignTokens.Spacing.md)
            .frame(width: 230, alignment: .leading)
            .frame(minHeight: 210, alignment: .leading)
            .background(cardBackground)
            .overlay(alignment: .topLeading) {
                topAccent
            }
            .overlay(cardBorder)
            .opacity(isSelected ? 1.0 : 0.88)
            .shadow(
                color: palette.shadowColor.opacity(isSelected ? 1 : 0.7),
                radius: isSelected ? DesignTokens.Elevation.medium : DesignTokens.Elevation.low,
                x: 0,
                y: isSelected ? 8 : 4
            )
            .scaleEffect(isSelected ? 1 : 0.985)
            .animation(DesignTokens.Motion.reveal, value: isSelected)
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 9) {
            collectionMetadata
            runicPreview
            latinPreview
            collectionTitle
            collectionSubtitle
            authorPreview
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xl)
            .fill(cardBackgroundColor)
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xl)
            .stroke(
                isSelected ? palette.strongCardStroke : palette.cardStroke,
                lineWidth: isSelected ? DesignTokens.Stroke.emphasis : DesignTokens.Stroke.hairline
            )
    }

    private var topAccent: some View {
        Capsule()
            .fill(
                LinearGradient(
                    colors: gradientColors,
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: isSelected ? 88 : 58, height: 4)
            .padding(.top, DesignTokens.Spacing.sm)
            .padding(.leading, DesignTokens.Spacing.md)
    }

    private var collectionMetadata: some View {
        HStack(alignment: .top) {
            Label(cover.collection.displayName, systemImage: cover.collection.systemImage)
                .font(DesignTokens.Typography.label)
                .foregroundStyle(palette.textPrimary)
                .labelStyle(.titleAndIcon)

            Spacer(minLength: 8)

            Text("\(cover.quoteCount)")
                .font(DesignTokens.Typography.metadata)
                .foregroundStyle(palette.textPrimary)
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background {
                    Capsule()
                        .fill(isSelected ? palette.chipSelectedFill : palette.bannerBackground)
                }
        }
    }

    private var runicPreview: some View {
        Text(cover.runicPreview)
            .runicTextStyle(
                script: script,
                font: font,
                style: .body,
                minSize: 18,
                maxSize: 30
            )
            .foregroundStyle(palette.runeText)
            .lineLimit(2)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .topLeading)
    }

    private var latinPreview: some View {
        Text(cover.latinPreview)
            .font(DesignTokens.Typography.label)
            .foregroundStyle(palette.textSecondary)
            .lineLimit(2)
    }

    private var collectionTitle: some View {
        Text(cover.collection.displayName)
            .font(DesignTokens.Typography.cardTitle)
            .foregroundStyle(palette.textPrimary)
    }

    private var collectionSubtitle: some View {
        Text(cover.collection.subtitle)
            .font(DesignTokens.Typography.callout)
            .foregroundStyle(palette.textSecondary)
            .lineLimit(2)
    }

    private var authorPreview: some View {
        Text("— \(cover.authorPreview)")
            .font(DesignTokens.Typography.label)
            .foregroundStyle(palette.textTertiary)
            .lineLimit(1)
    }

    private var cardBackgroundColor: Color {
        reduceTransparency
            ? palette.editorialSurface
            : (isSelected ? palette.editorialSurface : palette.editorialInset)
    }

    private var gradientColors: [Color] {
        let alpha = isSelected ? 1.0 : 0.85

        switch cover.collection {
        case .all:
            return [
                palette.accent.opacity(0.35 * alpha),
                palette.accentSecondary.opacity(0.72 * alpha)
            ]
        case .motivation:
            return [
                palette.warning.opacity(0.65 * alpha),
                palette.accent.opacity(0.72 * alpha)
            ]
        case .stoic:
            return [
                palette.textSecondary.opacity(0.6 * alpha),
                palette.textTertiary.opacity(0.7 * alpha)
            ]
        case .tolkien:
            return [
                palette.success.opacity(0.62 * alpha),
                palette.accentSecondary.opacity(0.7 * alpha)
            ]
        }
    }
}
