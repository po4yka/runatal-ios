//
//  QuotePacksView.swift
//  RunicQuotes
//
//  Created by Claude on 12.03.26.
//

import SwiftUI

/// Browse and search the catalog of quote packs.
struct QuotePacksView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.runicTheme) private var runicTheme
    @State private var packs: [QuotePack] = []
    @State private var errorMessage: String?
    @State private var searchText = ""
    @State private var selectedPack: QuotePack?

    private var palette: AppThemePalette {
        .themed(self.runicTheme, for: self.colorScheme)
    }

    private var filteredPacks: [QuotePack] {
        guard !self.searchText.isEmpty else { return self.packs }
        let query = self.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return self.packs.filter {
            $0.title.localizedStandardContains(query) ||
                $0.subtitle.localizedStandardContains(query)
        }
    }

    // MARK: - Body

    var body: some View {
        LiquidListScaffold(palette: self.palette) {
            Section {
                HeroHeader(
                    eyebrow: "Quote Packs",
                    title: "Collectible Volumes",
                    subtitle: "Curated additions that extend the library without changing the rhythm of reading.",
                    meta: ["\(self.filteredPacks.count) available"],
                    palette: self.palette,
                )
                .listRowInsets(EdgeInsets(
                    top: DesignTokens.Spacing.lg,
                    leading: DesignTokens.Spacing.md,
                    bottom: DesignTokens.Spacing.md,
                    trailing: DesignTokens.Spacing.md,
                ))
            }

            Section {
                if let errorMessage {
                    FeedbackBanner(palette: self.palette, tone: .error, title: "Couldn’t Load Packs", message: errorMessage)
                } else if self.filteredPacks.isEmpty {
                    EditorialEmptyState(
                        palette: self.palette,
                        icon: "books.vertical",
                        eyebrow: "No packs",
                        title: "Nothing matched that search",
                        message: "Try a broader title or clear the search field.",
                    )
                } else {
                    self.packList
                }
            }
        }
        .searchable(text: self.$searchText, prompt: "Search packs")
        .navigationTitle("Quote Packs")
        .task {
            do {
                self.packs = try QuotePack.loadCatalog()
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
        .navigationDestination(item: self.$selectedPack) { pack in
            QuotePackDetailView(pack: pack)
        }
    }

    // MARK: - Pack List

    private var packList: some View {
        ForEach(self.filteredPacks) { pack in
            self.packRow(for: pack)
        }
    }

    // MARK: - Pack Row

    private func packRow(for pack: QuotePack) -> some View {
        Button {
            self.selectedPack = pack
        } label: {
            CollectionShelfRow(
                palette: self.palette,
                eyebrow: "Pack",
                title: pack.title,
                subtitle: pack.subtitle,
                supporting: "\(pack.quoteCount) quotes",
                meta: [],
                leading: {
                    Text(pack.runicGlyph)
                        .font(.system(size: 32, weight: .medium, design: .serif))
                        .foregroundStyle(self.palette.runeText)
                        .frame(width: 44, alignment: .center)
                },
                trailing: {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(self.palette.textTertiary)
                },
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("pack_\(pack.id)")
        .accessibilityLabel("\(pack.title), \(pack.quoteCount) quotes")
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        QuotePacksView()
    }
}
