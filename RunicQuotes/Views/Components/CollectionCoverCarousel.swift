//
//  CollectionCoverCarousel.swift
//  RunicQuotes
//
//  Created by Codex on 2026-02-13.
//

import SwiftUI

/// Horizontal collection selector with cover cards for quick browsing.
struct CollectionCoverCarousel: View {
    let covers: [QuoteCollectionCover]
    let selectedCollection: QuoteCollection
    let script: RunicScript
    let font: RunicFont
    let palette: AppThemePalette
    let onCollectionSelected: (QuoteCollection) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Collections")
                    .font(.headline)
                    .foregroundColor(palette.primaryText)

                Spacer()

                Text(selectedCollection.displayName)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(palette.tertiaryText)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(covers) { cover in
                        coverCard(cover)
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .padding(.horizontal)
    }

    private func coverCard(_ cover: QuoteCollectionCover) -> some View {
        let isSelected = cover.collection == selectedCollection

        return Button {
            onCollectionSelected(cover.collection)
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    Image(systemName: cover.collection.systemImage)
                        .font(.caption.weight(.bold))
                        .foregroundColor(palette.primaryText)

                    Spacer(minLength: 8)

                    Text("\(cover.quoteCount)")
                        .font(.caption2.weight(.bold))
                        .foregroundColor(palette.primaryText)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(.white.opacity(isSelected ? 0.35 : 0.18))
                        )
                }

                Text(cover.runicPreview)
                    .runicTextStyle(
                        script: script,
                        font: font,
                        style: .body,
                        minSize: 18,
                        maxSize: 30
                    )
                    .foregroundColor(palette.primaryText)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, minHeight: 46, alignment: .topLeading)

                Text(cover.latinPreview)
                    .font(.caption)
                    .foregroundColor(palette.secondaryText)
                    .lineLimit(2)

                Text(cover.collection.displayName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(palette.primaryText)

                Text(cover.collection.subtitle)
                    .font(.caption2)
                    .foregroundColor(palette.tertiaryText)
                    .lineLimit(1)

                Text("— \(cover.authorPreview)")
                    .font(.caption2)
                    .foregroundColor(palette.tertiaryText)
                    .lineLimit(1)
            }
            .padding(12)
            .frame(width: 220, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: gradientColors(for: cover.collection, isSelected: isSelected),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        isSelected ? palette.accent : palette.divider,
                        lineWidth: isSelected ? 1.3 : 0.8
                    )
            )
            .shadow(
                color: .black.opacity(isSelected ? 0.28 : 0.16),
                radius: isSelected ? 12 : 7,
                x: 0,
                y: 5
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityIdentifier("collection_cover_\(cover.collection.rawValue)")
        .accessibilityLabel("\(cover.collection.displayName) collection")
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityHint("Double tap to browse \(cover.collection.displayName) quotes")
    }

    private func gradientColors(for collection: QuoteCollection, isSelected: Bool) -> [Color] {
        let alpha = isSelected ? 1.0 : 0.85

        switch collection {
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
