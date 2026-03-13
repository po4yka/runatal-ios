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
            VStack(alignment: .leading, spacing: 9) {
                collectionMetadata
                runicPreview
                latinPreview
                collectionTitle
                collectionSubtitle
                authorPreview
            }
            .padding(12)
            .frame(width: 210, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 14)
                    .fill(cardBackgroundColor)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        Color.white.opacity(isSelected ? 0.15 : 0.08),
                        lineWidth: isSelected ? 1.3 : 0.8
                    )
            }
            .overlay(alignment: .topLeading) {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: isSelected ? 74 : 52, height: 4)
                    .padding(.top, 9)
                    .padding(.leading, 10)
            }
            .opacity(isSelected ? 1.0 : 0.75)
            .shadow(
                color: .black.opacity(isSelected ? 0.28 : 0.16),
                radius: isSelected ? 12 : 7,
                x: 0,
                y: 5
            )
            .animation(AnimationPresets.gentleSpring, value: isSelected)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("collection_cover_\(cover.collection.rawValue)")
        .accessibilityLabel("\(cover.collection.displayName) collection")
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityHint("Double tap to browse \(cover.collection.displayName) quotes")
    }

    private var collectionMetadata: some View {
        HStack(alignment: .top) {
            Image(systemName: cover.collection.systemImage)
                .font(.caption.weight(.bold))
                .foregroundStyle(palette.primaryText)

            Spacer(minLength: 8)

            Text("\(cover.quoteCount)")
                .font(.caption2.weight(.bold))
                .foregroundStyle(palette.primaryText)
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background {
                    Capsule()
                        .fill(.white.opacity(isSelected ? 0.35 : 0.18))
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
            .foregroundStyle(palette.primaryText)
            .lineLimit(1)
            .frame(maxWidth: .infinity, minHeight: 34, alignment: .topLeading)
    }

    private var latinPreview: some View {
        Text(cover.latinPreview)
            .font(.caption)
            .foregroundStyle(palette.secondaryText)
            .lineLimit(1)
    }

    private var collectionTitle: some View {
        Text(cover.collection.displayName)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(palette.primaryText)
    }

    private var collectionSubtitle: some View {
        Text(cover.collection.subtitle)
            .font(.caption2)
            .foregroundStyle(palette.tertiaryText)
            .lineLimit(1)
    }

    private var authorPreview: some View {
        Text("— \(cover.authorPreview)")
            .font(.caption2)
            .foregroundStyle(palette.tertiaryText)
            .lineLimit(1)
    }

    private var cardBackgroundColor: Color {
        reduceTransparency
            ? Color.black.opacity(0.45)
            : Color.black.opacity(isSelected ? 0.25 : 0.16)
    }

    private var gradientColors: [Color] {
        let alpha = isSelected ? 1.0 : 0.85

        switch cover.collection {
        case .all:
            return [
                Color.white.opacity(0.10 * alpha),
                Color.black.opacity(0.22 * alpha)
            ]
        case .motivation:
            return [
                Color(red: 0.80, green: 0.44, blue: 0.14).opacity(0.55 * alpha),
                Color(red: 0.57, green: 0.23, blue: 0.08).opacity(0.65 * alpha)
            ]
        case .stoic:
            return [
                Color(red: 0.28, green: 0.38, blue: 0.50).opacity(0.56 * alpha),
                Color(red: 0.17, green: 0.23, blue: 0.33).opacity(0.66 * alpha)
            ]
        case .tolkien:
            return [
                Color(red: 0.21, green: 0.42, blue: 0.27).opacity(0.56 * alpha),
                Color(red: 0.12, green: 0.25, blue: 0.18).opacity(0.66 * alpha)
            ]
        }
    }
}
