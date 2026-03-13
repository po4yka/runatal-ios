//
//  TranslationModels.swift
//  RunicQuotes
//
//  Created by Codex on 2026-03-13.
//

import Foundation

// MARK: - Core Enums

/// Presentation mode for the translation screen.
enum TranslationMode: String, Codable, CaseIterable, Identifiable, Sendable {
    case transliterate = "TRANSLITERATE"
    case translate = "TRANSLATE"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .transliterate:
            return "Transliterate"
        case .translate:
            return "Translate"
        }
    }

    static let `default` = TranslationMode.transliterate
}

/// Fidelity level for historical translation output.
enum TranslationFidelity: String, Codable, CaseIterable, Identifiable, Sendable {
    case strict = "STRICT"
    case readable = "READABLE"
    case decorative = "DECORATIVE"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .strict:
            return "Strict"
        case .readable:
            return "Readable"
        case .decorative:
            return "Decorative"
        }
    }

    static let `default` = TranslationFidelity.strict
}

/// Supported source-language set for the historical translation pipeline.
enum TranslationSourceLanguage: String, Codable, CaseIterable, Identifiable, Sendable {
    case english = "ENGLISH"
    case unsupported = "UNSUPPORTED"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english:
            return "English"
        case .unsupported:
            return "Unsupported"
        }
    }

    var isSupported: Bool {
        self == .english
    }
}

/// Evidence ceiling for requests that need stricter attestation requirements.
enum TranslationEvidenceCap: String, Codable, CaseIterable, Identifiable, Sendable {
    case fullDataset = "FULL_DATASET"
    case attestedOnly = "ATTESTED_ONLY"

    var id: String { rawValue }
}

/// Historical confidence tier for a translation result.
enum TranslationResolutionStatus: String, Codable, CaseIterable, Identifiable, Sendable {
    case attested = "ATTESTED"
    case reconstructed = "RECONSTRUCTED"
    case approximated = "APPROXIMATED"
    case unavailable = "UNAVAILABLE"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .attested:
            return "Attested"
        case .reconstructed:
            return "Reconstructed"
        case .approximated:
            return "Approximation"
        case .unavailable:
            return "Unavailable"
        }
    }
}

/// User-facing statement about how broadly the result is supported.
enum TranslationSupportLevel: String, Codable, CaseIterable, Identifiable, Sendable {
    case supported = "SUPPORTED"
    case partial = "PARTIAL"
    case unsupported = "UNSUPPORTED"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .supported:
            return "Supported"
        case .partial:
            return "Partial"
        case .unsupported:
            return "Unsupported"
        }
    }
}

/// User-facing evidence badge.
enum TranslationEvidenceTier: String, Codable, CaseIterable, Identifiable, Sendable {
    case attested = "ATTESTED"
    case reconstructed = "RECONSTRUCTED"
    case approximate = "APPROXIMATE"
    case unsupported = "UNSUPPORTED"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .attested:
            return "Attested"
        case .reconstructed:
            return "Reconstructed"
        case .approximate:
            return "Approximate"
        case .unsupported:
            return "Unsupported"
        }
    }
}

/// Dataset-level evidence state for curated rows.
enum TranslationAttestationStatus: String, Codable, CaseIterable, Identifiable, Sendable {
    case attested = "ATTESTED"
    case reconstructed = "RECONSTRUCTED"
    case fallback = "FALLBACK"

    var id: String { rawValue }
}

/// Inventory split used by the curation source of truth.
enum TranslationInventoryKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case attestedFormula = "ATTESTED_FORMULA"
    case approvedReconstruction = "APPROVED_RECONSTRUCTION"
    case readableParaphrase = "READABLE_PARAPHRASE"
    case decorativeFallback = "DECORATIVE_FALLBACK"

    var id: String { rawValue }

    var isStrictEligible: Bool {
        switch self {
        case .attestedFormula, .approvedReconstruction:
            return true
        case .readableParaphrase, .decorativeFallback:
            return false
        }
    }
}

/// Explains how a historical translation result was derived.
enum TranslationDerivationKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case goldExample = "GOLD_EXAMPLE"
    case phraseTemplate = "PHRASE_TEMPLATE"
    case tokenComposed = "TOKEN_COMPOSED"
    case sequenceTranscription = "SEQUENCE_TRANSCRIPTION"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .goldExample:
            return "Gold example"
        case .phraseTemplate:
            return "Phrase template"
        case .tokenComposed:
            return "Token composed"
        case .sequenceTranscription:
            return "Sequence transcription"
        }
    }
}

/// Intermediate language stage used before glyph rendering.
enum HistoricalStage: String, Codable, CaseIterable, Identifiable, Sendable {
    case oldNorse = "OLD_NORSE"
    case protoNorse = "PROTO_NORSE"
    case ereborEnglish = "EREBOR_ENGLISH"
    case modernEnglish = "MODERN_ENGLISH"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .oldNorse:
            return "Old Norse"
        case .protoNorse:
            return "Proto-Norse"
        case .ereborEnglish:
            return "Erebor English"
        case .modernEnglish:
            return "Modern English"
        }
    }
}

/// Rendering variant for Younger Futhark.
enum YoungerFutharkVariant: String, Codable, CaseIterable, Identifiable, Sendable {
    case longBranch = "LONG_BRANCH"
    case shortTwig = "SHORT_TWIG"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .longBranch:
            return "Long-branch"
        case .shortTwig:
            return "Short-twig"
        }
    }

    static let `default` = YoungerFutharkVariant.longBranch
}

// MARK: - Structured Output

/// Source attribution for a translated result or one of its stages.
struct TranslationProvenanceEntry: Codable, Hashable, Sendable {
    let sourceID: String
    let referenceID: String?
    let label: String
    let role: String
    let license: String
    let sourceWork: String?
    let licenseNote: String?
    let attestationStatus: TranslationAttestationStatus?
    let lemmaAuthorityID: String?
    let grammaticalClass: String?
    let historicalStage: String?
    let regressionID: String?
    let detail: String?
    let url: String?

    private enum CodingKeys: String, CodingKey {
        case sourceID = "sourceId"
        case referenceID = "referenceId"
        case label
        case role
        case license
        case sourceWork
        case licenseNote
        case attestationStatus
        case lemmaAuthorityID = "lemmaAuthorityId"
        case grammaticalClass
        case historicalStage
        case regressionID = "regressionId"
        case detail
        case url
    }
}

/// Per-token translation trace for educational UI and persistence.
struct TranslationTokenBreakdown: Codable, Hashable, Sendable, Identifiable {
    let sourceToken: String
    let normalizedToken: String
    let diplomaticToken: String
    let glyphToken: String
    let resolutionStatus: TranslationResolutionStatus
    let provenance: [TranslationProvenanceEntry]

    var id: String {
        "\(sourceToken)|\(normalizedToken)|\(diplomaticToken)|\(glyphToken)"
    }
}

/// Input for a historical translation engine.
struct TranslationRequest: Codable, Hashable, Sendable {
    let sourceText: String
    let script: RunicScript
    let fidelity: TranslationFidelity
    let youngerVariant: YoungerFutharkVariant
    let sourceLanguage: TranslationSourceLanguage
    let evidenceCap: TranslationEvidenceCap

    init(
        sourceText: String,
        script: RunicScript,
        fidelity: TranslationFidelity = .default,
        youngerVariant: YoungerFutharkVariant = .default,
        sourceLanguage: TranslationSourceLanguage = .english,
        evidenceCap: TranslationEvidenceCap = .fullDataset
    ) {
        self.sourceText = sourceText
        self.script = script
        self.fidelity = fidelity
        self.youngerVariant = youngerVariant
        self.sourceLanguage = sourceLanguage
        self.evidenceCap = evidenceCap
    }
}

/// Structured translation output with intermediate layers.
struct TranslationResult: Codable, Hashable, Sendable {
    let sourceText: String
    let script: RunicScript
    let fidelity: TranslationFidelity
    let derivationKind: TranslationDerivationKind
    let historicalStage: HistoricalStage
    let normalizedForm: String
    let diplomaticForm: String
    let glyphOutput: String
    let requestedVariant: String?
    let resolutionStatus: TranslationResolutionStatus
    let supportLevel: TranslationSupportLevel
    let evidenceTier: TranslationEvidenceTier
    let confidence: Double
    let notes: [String]
    let unresolvedTokens: [String]
    let provenance: [TranslationProvenanceEntry]
    let tokenBreakdown: [TranslationTokenBreakdown]
    let attestationRefs: [String]
    let inputLanguage: TranslationSourceLanguage
    let userFacingWarnings: [String]
    let engineVersion: String
    let datasetVersion: String
    let createdAt: Date
    let updatedAt: Date

    init(
        sourceText: String,
        script: RunicScript,
        fidelity: TranslationFidelity,
        derivationKind: TranslationDerivationKind = .tokenComposed,
        historicalStage: HistoricalStage,
        normalizedForm: String,
        diplomaticForm: String,
        glyphOutput: String,
        requestedVariant: String? = nil,
        resolutionStatus: TranslationResolutionStatus = .unavailable,
        supportLevel: TranslationSupportLevel? = nil,
        evidenceTier: TranslationEvidenceTier? = nil,
        confidence: Double = 0,
        notes: [String] = [],
        unresolvedTokens: [String] = [],
        provenance: [TranslationProvenanceEntry] = [],
        tokenBreakdown: [TranslationTokenBreakdown] = [],
        attestationRefs: [String] = [],
        inputLanguage: TranslationSourceLanguage = .english,
        userFacingWarnings: [String] = [],
        engineVersion: String,
        datasetVersion: String,
        createdAt: Date = Date(),
        updatedAt: Date? = nil
    ) {
        self.sourceText = sourceText
        self.script = script
        self.fidelity = fidelity
        self.derivationKind = derivationKind
        self.historicalStage = historicalStage
        self.normalizedForm = normalizedForm
        self.diplomaticForm = diplomaticForm
        self.glyphOutput = glyphOutput
        self.requestedVariant = requestedVariant
        self.resolutionStatus = resolutionStatus
        self.supportLevel = supportLevel ?? TranslationResult.defaultSupportLevel(for: resolutionStatus)
        self.evidenceTier = evidenceTier ?? TranslationResult.defaultEvidenceTier(for: resolutionStatus)
        self.confidence = confidence
        self.notes = notes
        self.unresolvedTokens = unresolvedTokens
        self.provenance = provenance
        self.tokenBreakdown = tokenBreakdown
        self.attestationRefs = attestationRefs
        self.inputLanguage = inputLanguage
        self.userFacingWarnings = userFacingWarnings
        self.engineVersion = engineVersion
        self.datasetVersion = datasetVersion
        self.createdAt = createdAt
        self.updatedAt = updatedAt ?? createdAt
    }

    var isAvailable: Bool {
        resolutionStatus != .unavailable && !glyphOutput.isEmpty
    }

    var primaryProvenance: TranslationProvenanceEntry? {
        provenance.first
    }

    var primaryEvidenceLabel: String? {
        primaryProvenance?.label
    }

    static func defaultSupportLevel(for resolutionStatus: TranslationResolutionStatus) -> TranslationSupportLevel {
        switch resolutionStatus {
        case .attested, .reconstructed:
            return .supported
        case .approximated:
            return .partial
        case .unavailable:
            return .unsupported
        }
    }

    static func defaultEvidenceTier(for resolutionStatus: TranslationResolutionStatus) -> TranslationEvidenceTier {
        switch resolutionStatus {
        case .attested:
            return .attested
        case .reconstructed:
            return .reconstructed
        case .approximated:
            return .approximate
        case .unavailable:
            return .unsupported
        }
    }
}

// MARK: - Script Mapping

extension RunicScript {
    var translationScriptName: String {
        switch self {
        case .elder:
            return "ELDER_FUTHARK"
        case .younger:
            return "YOUNGER_FUTHARK"
        case .cirth:
            return "CIRTH"
        }
    }
}
