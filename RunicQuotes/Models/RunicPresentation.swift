//
//  RunicPresentation.swift
//  RunicQuotes
//
//  Created by Claude on 09.10.26.
//

import Foundation

enum RunicPresentationSource: String, Codable, CaseIterable, Identifiable, Sendable {
    var id: String {
        self.rawValue
    }

    case structuredTranslation
    case structuredTranscription
    case savedHistoricalArtifact
    case savedRunicText
    case storedTransliteration
    case liveTransliteration

    var disclosureTitle: String {
        switch self {
        case .structuredTranslation:
            "Structured historical translation"
        case .structuredTranscription:
            "Structured spelling transcription"
        case .savedHistoricalArtifact:
            "Saved structured result"
        case .savedRunicText:
            "Saved runic text"
        case .storedTransliteration:
            "Stored transliteration"
        case .liveTransliteration:
            "On-demand transliteration"
        }
    }

    func evidenceLabel(_ tier: TranslationEvidenceTier) -> String {
        self == .savedHistoricalArtifact ? "Recorded evidence: \(tier.displayName)" : tier.displayName
    }

    var shareDisclosureTitle: String {
        switch self {
        case .structuredTranslation:
            "Historical translation"
        case .structuredTranscription:
            "Spelling transcription"
        case .savedHistoricalArtifact:
            "Saved structured result"
        case .savedRunicText:
            "Saved runic text"
        case .storedTransliteration:
            "Stored transliteration"
        case .liveTransliteration:
            "Transliteration fallback"
        }
    }
}

struct ResolvedRunicPresentation: Codable, Hashable, Sendable {
    var warnings: [String] = []
    var isRenderable = true
    var savedArtifact: TranslationResult?
    let text: String
    let source: RunicPresentationSource
    let evidenceTier: TranslationEvidenceTier?
    let primarySourceLabel: String?
}

struct RunicPresentationInput: Sendable {
    let textLatin: String
    let storedText: String?
    let script: RunicScript
    let cirthEncoding: String?
    let savedMetadata: Data?

    init(quote: QuoteRecord, script: RunicScript) {
        self.textLatin = quote.textLatin
        self.storedText = quote.runicText(for: script)
        self.script = script
        self.cirthEncoding = quote.cirthEncodingRaw
        self.savedMetadata = quote.storedTranslationMetadataData
    }

    init(textLatin: String, storedText: String?, script: RunicScript, cirthEncoding: String?, savedMetadata: Data?) {
        self.textLatin = textLatin
        self.storedText = storedText
        self.script = script
        self.cirthEncoding = cirthEncoding
        self.savedMetadata = savedMetadata
    }
}

enum RunicPresentationResolver {
    static func resolve(_ input: RunicPresentationInput, currentCache: TranslationResult?) -> ResolvedRunicPresentation {
        let stored = input.storedText ?? ""
        if input.script == .cirth, input.cirthEncoding == "CIRTH_UNKNOWN_V0" {
            return ResolvedRunicPresentation(
                warnings: ["The saved Cirth encoding is unknown. Original glyph data is preserved, but it cannot be rendered with the current font."],
                isRenderable: false,
                text: stored,
                source: .savedRunicText,
                evidenceTier: nil,
                primarySourceLabel: "Saved output in an unknown font encoding.",
            )
        }
        if !stored.isEmpty, let artifact = self.validArtifact(input, stored: stored) {
            return ResolvedRunicPresentation(
                warnings: self.savedWarnings(for: artifact, input: input),
                savedArtifact: artifact,
                text: stored,
                source: .savedHistoricalArtifact,
                evidenceTier: artifact.evidenceTier,
                primarySourceLabel: [artifact.primaryEvidenceLabel, "Saved assessment: \(artifact.engineVersion) / \(artifact.datasetVersion)"].compactMap { $0 }.joined(separator: " • "),
            )
        }
        let generated = RunicTransliterator.transliterate(input.textLatin, to: input.script)
        if !stored.isEmpty, input.savedMetadata != nil || stored != generated.glyphOutput {
            return ResolvedRunicPresentation(
                warnings: generated.warnings,
                text: stored,
                source: .savedRunicText,
                evidenceTier: nil,
                primarySourceLabel: "Saved output; the original assessment is unavailable.",
            )
        }
        // The repository owns engine/dataset approval. This guard also prevents a newer cache
        // result from being paired with an older quote snapshot read before an edit.
        if let cached = currentCache, cached.isAvailable, cached.script == input.script, cached.sourceText == input.textLatin {
            return ResolvedRunicPresentation(
                warnings: cached.userFacingWarnings,
                text: cached.glyphOutput,
                source: input.script == .cirth ? .structuredTranscription : .structuredTranslation,
                evidenceTier: cached.evidenceTier,
                primarySourceLabel: cached.primaryEvidenceLabel,
            )
        }
        return ResolvedRunicPresentation(
            warnings: generated.warnings,
            text: stored.isEmpty ? generated.glyphOutput : stored,
            source: stored.isEmpty ? .liveTransliteration : .storedTransliteration,
            evidenceTier: nil,
            primarySourceLabel: nil,
        )
    }

    private static func savedWarnings(for artifact: TranslationResult, input: RunicPresentationInput) -> [String] {
        var warnings = artifact.userFacingWarnings + ["This is a saved assessment; it has not been rechecked by the current engine."]
        let variant = artifact.requestedVariant.flatMap(YoungerFutharkVariant.init(rawValue:)) ?? .longBranch
        let unsupported = HistoricalGlyphInventory.unsupportedGlyphs(in: artifact.glyphOutput, sourceText: input.textLatin, script: input.script, variant: variant)
        if !unsupported.isEmpty {
            warnings.append("Saved output contains glyphs outside the current script inventory: \(unsupported.joined(separator: ", ")).")
        }
        return warnings
    }

    private static func validArtifact(_ input: RunicPresentationInput, stored: String) -> TranslationResult? {
        guard let data = input.savedMetadata, let artifacts = try? JSONDecoder().decode([TranslationResult].self, from: data) else { return nil }
        return artifacts.first { artifact in
            artifact.confidence.isFinite && (0 ... 1).contains(artifact.confidence)
                && !artifact.engineVersion.isEmpty && !artifact.datasetVersion.isEmpty
                && artifact.isAvailable && artifact.script == input.script
                && artifact.sourceText == input.textLatin && artifact.glyphOutput == stored
        }
    }
}
