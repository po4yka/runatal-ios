//
//  RuneDetailView.swift
//  RunicQuotes
//
//  Created by Claude on 12.03.26.
//

import SwiftUI

/// Detail view for a single rune showing glyph, metadata, and description.
struct RuneDetailView: View {
    let rune: RuneInfo
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.runicTheme) private var runicTheme

    private var palette: AppThemePalette {
        .themed(self.runicTheme, for: self.colorScheme)
    }

    /// Position of this rune within its script catalog (1-based).
    private var position: String {
        let allRunes = RuneInfo.runes(for: self.rune.script)
        let index = allRunes.firstIndex(where: { $0.id == self.rune.id }).map { $0 + 1 } ?? 0
        return "\(index)/\(allRunes.count)"
    }

    /// Unicode code point string (e.g. "U+16A8").
    private var unicodeLabel: String {
        guard let scalar = rune.glyph.unicodeScalars.first else { return "--" }
        let codePoint = String(scalar.value, radix: 16, uppercase: true)
        let padding = String(repeating: "0", count: max(0, 4 - codePoint.count))
        return "U+\(padding)\(codePoint)"
    }

    /// Aett grouping for Elder Futhark runes (groups of 8).
    private var aett: String? {
        guard self.rune.script == .elder else { return nil }
        let allRunes = RuneInfo.elderFuthark
        guard let index = allRunes.firstIndex(where: { $0.id == rune.id }) else { return nil }
        switch index / 8 {
        case 0: return "Freyr"
        case 1: return "Hagal"
        case 2: return "Tyr"
        default: return nil
        }
    }

    // MARK: - Body

    var body: some View {
        LiquidContentScaffold(
            palette: self.palette,
            spacing: DesignTokens.Spacing.lg,
            showBackgroundExtension: false,
        ) {
            HeroHeader(
                eyebrow: self.rune.script.displayName,
                title: self.rune.name,
                subtitle: "\(self.rune.meaning) · /\(self.rune.sound)/",
                meta: [self.position, self.unicodeLabel],
                palette: self.palette,
            )

            self.heroSection
            self.aboutSection
        }
        .navigationTitle(self.rune.name)
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        ContentPlate(
            palette: self.palette,
            tone: .hero,
            cornerRadius: DesignTokens.CornerRadius.xxl,
            shadowRadius: DesignTokens.Elevation.medium,
        ) {
            VStack(spacing: DesignTokens.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(self.palette.bannerBackground)
                        .frame(width: 96, height: 96)

                    Text(self.rune.glyph)
                        .font(.custom(RunicFontConfiguration.fontName(for: self.rune.script, font: .noto), size: 46))
                        .foregroundStyle(self.palette.runeText)
                }

                self.infoRow
            }
        }
    }

    // MARK: - Info Row

    private var infoRow: some View {
        HStack(spacing: 0) {
            if let aett {
                self.infoColumn(label: "Aett", value: aett)
            }

            self.infoColumn(label: self.rune.script == .cirth ? "Private use" : "Unicode", value: self.unicodeLabel)

            self.infoColumn(label: "Position", value: self.position)
        }
        .padding(.horizontal, DesignTokens.Spacing.lg)
        .padding(.vertical, DesignTokens.Spacing.xs)
    }

    private func infoColumn(label: String, value: String) -> some View {
        VStack(spacing: DesignTokens.Spacing.xxs) {
            Text(label)
                .font(DesignTokens.Typography.listMeta)
                .foregroundStyle(self.palette.textTertiary)

            Text(value)
                .font(DesignTokens.Typography.controlLabel.weight(.bold))
                .foregroundStyle(self.palette.textPrimary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - About Section

    private var aboutSection: some View {
        ContentPlate(
            palette: self.palette,
            tone: .secondary,
            cornerRadius: DesignTokens.CornerRadius.xl,
            shadowRadius: 0,
        ) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                SectionLabel(title: "Historical reference", palette: self.palette)
                Text(self.rune.nameEvidence.displayName)
                    .font(DesignTokens.Typography.controlLabel)
                    .foregroundStyle(self.palette.textSecondary)
                Text(self.rune.historicalNote)
                    .font(DesignTokens.Typography.supportingBody)
                    .foregroundStyle(self.palette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                ForEach(self.rune.referenceSources) { source in
                    if let url = URL(string: source.url) {
                        Link(source.title, destination: url)
                            .font(DesignTokens.Typography.supportingBody)
                    }
                }
                if let reflection = self.rune.modernReflection {
                    SectionLabel(title: "Modern reflection", palette: self.palette)
                    Text("Contemporary prompts written by Runatal; not attested ancient divination meanings.")
                        .font(DesignTokens.Typography.listMeta)
                        .foregroundStyle(self.palette.textTertiary)
                    Text(reflection)
                        .font(DesignTokens.Typography.supportingBody)
                        .foregroundStyle(self.palette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

}

// MARK: - Preview

#Preview {
    NavigationStack {
        RuneDetailView(rune: .sample)
    }
}
