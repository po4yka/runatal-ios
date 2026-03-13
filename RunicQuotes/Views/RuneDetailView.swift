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
                        .font(.system(size: 46))
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

            self.infoColumn(label: "Unicode", value: self.unicodeLabel)

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
                SectionLabel(title: "About", palette: self.palette)
                Text(self.runeDescription)
                    .font(DesignTokens.Typography.supportingBody)
                    .foregroundStyle(self.palette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    /// Description text for each rune.
    private var runeDescription: String {
        Self.descriptions[self.rune.id] ?? "\(self.rune.name) is a rune of the \(self.rune.script.displayName) alphabet representing \"\(self.rune.meaning)\" with the phonetic value /\(self.rune.sound)/."
    }

    // MARK: - Rune Descriptions

    private static let descriptions: [String: String] = [
        // Elder Futhark
        "elder-fehu": "Fehu represents wealth, prosperity, and abundance. In the ancient Norse tradition, cattle were a primary measure of wealth, making this rune deeply connected to material fortune and the energy needed to attain and maintain it.",
        "elder-uruz": "Uruz embodies the raw, untamed power of the aurochs, the wild ox of ancient Europe. It represents physical strength, endurance, and the primal creative force that drives transformation.",
        "elder-thurisaz": "Thurisaz is the rune of the giants and of Thor's hammer. It represents reactive force, defense, and the power of chaos that can be directed for protection or destruction.",
        "elder-ansuz": "Ansuz represents divine inspiration, communication, and the breath of Odin. It is the rune of wisdom, poetry, and the power of words to shape reality.",
        "elder-raidho": "Raidho is the rune of the journey, both physical and spiritual. It represents right action, cosmic order, and the rhythmic movement that underlies all of existence.",
        "elder-kenaz": "Kenaz is the torch that illuminates the darkness. It represents knowledge, creativity, and the transformative power of controlled fire in craft and art.",
        "elder-gebo": "Gebo is the rune of gifts and sacred exchange. It represents generosity, partnership, and the balance of giving and receiving that maintains relationships.",
        "elder-wunjo": "Wunjo embodies joy, harmony, and fulfillment. It represents the bliss that comes from alignment with one's true nature and fellowship with others.",
        "elder-hagalaz": "Hagalaz is the rune of hail and disruption. It represents the uncontrollable forces of nature that break down the old to make way for new growth.",
        "elder-naudiz": "Naudiz represents need, constraint, and the friction of resistance. It teaches that necessity is the mother of invention and that hardship forges strength.",
        "elder-isa": "Isa is the rune of ice and stillness. It represents a period of waiting, concentration, and the crystalline clarity that comes from absolute focus.",
        "elder-jera": "Jera is the rune of the year and harvest. It represents the natural cycle of cause and effect, patience, and the rewards that come from sustained effort.",
        "elder-eihwaz": "Eihwaz is the rune of the yew tree, the axis between worlds. It represents endurance, the connection between life and death, and spiritual resilience.",
        "elder-perthro": "Perthro is the rune of mystery, fate, and the unknown. It represents the well of destiny, chance, and the hidden forces that shape outcomes.",
        "elder-algiz": "Algiz is the rune of protection and the divine connection. It represents the instinct for self-preservation and the bridge between humanity and the gods.",
        "elder-sowilo": "Sowilo is the rune of the sun and victory. It represents wholeness, life force, and the guiding light that leads to success and self-realization.",
        "elder-tiwaz": "Tiwaz is the rune of the god Tyr, embodying honor, justice, and self-sacrifice. It represents the warrior spirit guided by duty and moral courage.",
        "elder-berkano": "Berkano is the rune of the birch tree and new beginnings. It represents birth, growth, fertility, and the nurturing energy of renewal.",
        "elder-ehwaz": "Ehwaz is the rune of the horse and trusted partnership. It represents loyalty, teamwork, and the harmonious bond between rider and steed.",
        "elder-mannaz": "Mannaz is the rune of humankind and shared intelligence. It represents the self, social bonds, and the collective wisdom of human experience.",
        "elder-laguz": "Laguz is the rune of water and the flow of life. It represents intuition, the subconscious, and the power of going with the current.",
        "elder-ingwaz": "Ingwaz is the rune of the god Ing and internal growth. It represents gestation, potential energy, and the seed of transformation held within.",
        "elder-dagaz": "Dagaz is the rune of day and breakthrough. It represents the dawn, radical transformation, and the moment of clarity when darkness gives way to light.",
        "elder-othala": "Othala is the rune of heritage and ancestral property. It represents homeland, inheritance, and the spiritual legacy passed down through generations.",
    ]
}

// MARK: - Preview

#Preview {
    NavigationStack {
        RuneDetailView(rune: .sample)
    }
}
