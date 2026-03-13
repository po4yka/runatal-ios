//
//  TranslationDataset.swift
//  RunicQuotes
//
//  Created by Codex on 2026-03-13.
//

import Foundation

// MARK: - Store Protocols

protocol HistoricalLexiconStore {
    func datasetManifest() -> TranslationDatasetManifest
    func sourceManifest() -> TranslationSourceManifest
    func oldNorseLexicon() -> [OldNorseLexiconEntry]
    func protoNorseLexicon() -> [ProtoNorseLexiconEntry]
    func paradigmTables() -> ParadigmTablesData
    func grammarRules() -> GrammarRulesData
    func nameAdaptations() -> NameAdaptationsData
    func fallbackTemplates() -> FallbackTemplatesData
}

protocol RunicCorpusStore {
    func datasetManifest() -> TranslationDatasetManifest
    func sourceManifest() -> TranslationSourceManifest
    func youngerPhraseTemplates() -> [HistoricalPhraseTemplateEntry]
    func elderAttestedForms() -> [HistoricalPhraseTemplateEntry]
    func runicCorpusReferences() -> [RunicCorpusReferenceEntry]
    func goldExamples() -> [TranslationGoldExampleEntry]
}

protocol EreborOrthographyStore {
    func datasetManifest() -> TranslationDatasetManifest
    func sourceManifest() -> TranslationSourceManifest
    func ereborTables() -> EreborTablesData
}

// MARK: - Dataset Models

struct TranslationDatasetManifest: Codable, Sendable {
    let version: String
    let generatedAt: String
    let generatedBy: String
    let notes: [String]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try container.decode(String.self, forKey: .version)
        generatedAt = try container.decode(String.self, forKey: .generatedAt)
        generatedBy = try container.decode(String.self, forKey: .generatedBy)
        notes = try container.decodeIfPresent([String].self, forKey: .notes) ?? []
    }
}

struct OldNorseLexiconEntry: Codable, Sendable {
    let id: String
    let english: String
    let partOfSpeech: String
    let lemma: String
    let paradigmID: String?
    let present3sg: String?
    let past3sg: String?
    let pluralForm: String?
    let dativePhrase: String?
    let strictEligible: Bool
    let sourceID: String
    let citations: [String]

    private enum CodingKeys: String, CodingKey {
        case id
        case english
        case partOfSpeech
        case lemma
        case paradigmID = "paradigmId"
        case present3sg
        case past3sg
        case pluralForm
        case dativePhrase
        case strictEligible
        case sourceID = "sourceId"
        case citations
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        english = try container.decode(String.self, forKey: .english)
        partOfSpeech = try container.decode(String.self, forKey: .partOfSpeech)
        lemma = try container.decode(String.self, forKey: .lemma)
        paradigmID = try container.decodeIfPresent(String.self, forKey: .paradigmID)
        present3sg = try container.decodeIfPresent(String.self, forKey: .present3sg)
        past3sg = try container.decodeIfPresent(String.self, forKey: .past3sg)
        pluralForm = try container.decodeIfPresent(String.self, forKey: .pluralForm)
        dativePhrase = try container.decodeIfPresent(String.self, forKey: .dativePhrase)
        strictEligible = try container.decodeIfPresent(Bool.self, forKey: .strictEligible) ?? true
        sourceID = try container.decode(String.self, forKey: .sourceID)
        citations = try container.decodeIfPresent([String].self, forKey: .citations) ?? []
    }
}

struct ProtoNorseLexiconEntry: Codable, Sendable {
    let id: String
    let english: String
    let form: String
    let partOfSpeech: String
    let strictEligible: Bool
    let sourceID: String
    let citations: [String]

    private enum CodingKeys: String, CodingKey {
        case id
        case english
        case form
        case partOfSpeech
        case strictEligible
        case sourceID = "sourceId"
        case citations
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        english = try container.decode(String.self, forKey: .english)
        form = try container.decode(String.self, forKey: .form)
        partOfSpeech = try container.decode(String.self, forKey: .partOfSpeech)
        strictEligible = try container.decodeIfPresent(Bool.self, forKey: .strictEligible) ?? false
        sourceID = try container.decode(String.self, forKey: .sourceID)
        citations = try container.decodeIfPresent([String].self, forKey: .citations) ?? []
    }
}

struct ParadigmTablesData: Codable, Sendable {
    let nounParadigms: [String: NounParadigm]
    let verbParadigms: [String: VerbParadigm]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        nounParadigms = try container.decodeIfPresent([String: NounParadigm].self, forKey: .nounParadigms) ?? [:]
        verbParadigms = try container.decodeIfPresent([String: VerbParadigm].self, forKey: .verbParadigms) ?? [:]
    }
}

struct NounParadigm: Codable, Sendable {
    let nominativeSingularSuffix: String
    let pluralSuffix: String
}

struct VerbParadigm: Codable, Sendable {
    let thirdPersonPresentSuffix: String
    let thirdPersonPastSuffix: String
}

struct EreborTablesData: Codable, Sendable {
    let phraseMappings: [EreborPhraseMappingEntry]
    let sequences: [String: String]
    let singleCharacters: [String: String]
    let longVowels: [String: String]
    let longConsonants: [String: String]
    let wordSeparator: String

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        phraseMappings = try container.decodeIfPresent([EreborPhraseMappingEntry].self, forKey: .phraseMappings) ?? []
        sequences = try container.decodeIfPresent([String: String].self, forKey: .sequences) ?? [:]
        singleCharacters = try container.decodeIfPresent([String: String].self, forKey: .singleCharacters) ?? [:]
        longVowels = try container.decodeIfPresent([String: String].self, forKey: .longVowels) ?? [:]
        longConsonants = try container.decodeIfPresent([String: String].self, forKey: .longConsonants) ?? [:]
        wordSeparator = try container.decodeIfPresent(String.self, forKey: .wordSeparator) ?? "·"
    }
}

struct EreborPhraseMappingEntry: Codable, Sendable {
    let id: String
    let sourceText: String
    let diplomaticForm: String
    let glyphOutput: String
    let resolutionStatus: String
    let notes: [String]
    let referenceIDs: [String]

    private enum CodingKeys: String, CodingKey {
        case id
        case sourceText
        case diplomaticForm
        case glyphOutput
        case resolutionStatus
        case notes
        case referenceIDs = "referenceIds"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        sourceText = try container.decode(String.self, forKey: .sourceText)
        diplomaticForm = try container.decode(String.self, forKey: .diplomaticForm)
        glyphOutput = try container.decodeIfPresent(String.self, forKey: .glyphOutput) ?? ""
        resolutionStatus = try container.decodeIfPresent(String.self, forKey: .resolutionStatus) ?? "ATTESTED"
        notes = try container.decodeIfPresent([String].self, forKey: .notes) ?? []
        referenceIDs = try container.decodeIfPresent([String].self, forKey: .referenceIDs) ?? []
    }
}

struct GrammarRulesData: Codable, Sendable {
    let removableWords: [String]
    let prepositionMap: [String: String]
    let interrogatives: [String]
    let pronounMap: [String: String]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        removableWords = try container.decodeIfPresent([String].self, forKey: .removableWords) ?? []
        prepositionMap = try container.decodeIfPresent([String: String].self, forKey: .prepositionMap) ?? [:]
        interrogatives = try container.decodeIfPresent([String].self, forKey: .interrogatives) ?? []
        pronounMap = try container.decodeIfPresent([String: String].self, forKey: .pronounMap) ?? [:]
    }
}

struct NameAdaptationsData: Codable, Sendable {
    let names: [String: String]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        names = try container.decodeIfPresent([String: String].self, forKey: .names) ?? [:]
    }
}

struct FallbackTemplatesData: Codable, Sendable {
    let synonyms: [String: String]
    let paraphrases: [String: String]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        synonyms = try container.decodeIfPresent([String: String].self, forKey: .synonyms) ?? [:]
        paraphrases = try container.decodeIfPresent([String: String].self, forKey: .paraphrases) ?? [:]
    }
}

struct TranslationSourceManifest: Codable, Sendable {
    let sources: [TranslationSourceEntry]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        sources = try container.decodeIfPresent([TranslationSourceEntry].self, forKey: .sources) ?? []
    }
}

struct TranslationSourceEntry: Codable, Sendable {
    let id: String
    let name: String
    let role: String
    let license: String
    let url: String
}

struct RunicCorpusReferenceEntry: Codable, Sendable {
    let id: String
    let sourceID: String
    let label: String
    let detail: String
    let url: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case sourceID = "sourceId"
        case label
        case detail
        case url
    }
}

struct HistoricalPhraseTemplateEntry: Codable, Sendable {
    let id: String
    let script: String
    let fidelity: String
    let derivationKind: String
    let historicalStage: String
    let sourceText: String
    let normalizedForm: String
    let diplomaticForm: String
    let resolutionStatus: String
    let notes: [String]
    let referenceIDs: [String]
    let tokenBreakdown: [HistoricalTemplateTokenEntry]

    private enum CodingKeys: String, CodingKey {
        case id
        case script
        case fidelity
        case derivationKind
        case historicalStage
        case sourceText
        case normalizedForm
        case diplomaticForm
        case resolutionStatus
        case notes
        case referenceIDs = "referenceIds"
        case tokenBreakdown
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        script = try container.decode(String.self, forKey: .script)
        fidelity = try container.decode(String.self, forKey: .fidelity)
        derivationKind = try container.decode(String.self, forKey: .derivationKind)
        historicalStage = try container.decode(String.self, forKey: .historicalStage)
        sourceText = try container.decode(String.self, forKey: .sourceText)
        normalizedForm = try container.decode(String.self, forKey: .normalizedForm)
        diplomaticForm = try container.decode(String.self, forKey: .diplomaticForm)
        resolutionStatus = try container.decodeIfPresent(String.self, forKey: .resolutionStatus) ?? "RECONSTRUCTED"
        notes = try container.decodeIfPresent([String].self, forKey: .notes) ?? []
        referenceIDs = try container.decodeIfPresent([String].self, forKey: .referenceIDs) ?? []
        tokenBreakdown = try container.decodeIfPresent([HistoricalTemplateTokenEntry].self, forKey: .tokenBreakdown) ?? []
    }
}

struct HistoricalTemplateTokenEntry: Codable, Sendable {
    let sourceToken: String
    let normalizedToken: String
    let diplomaticToken: String
    let resolutionStatus: String
    let referenceIDs: [String]

    private enum CodingKeys: String, CodingKey {
        case sourceToken
        case normalizedToken
        case diplomaticToken
        case resolutionStatus
        case referenceIDs = "referenceIds"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        sourceToken = try container.decode(String.self, forKey: .sourceToken)
        normalizedToken = try container.decode(String.self, forKey: .normalizedToken)
        diplomaticToken = try container.decode(String.self, forKey: .diplomaticToken)
        resolutionStatus = try container.decodeIfPresent(String.self, forKey: .resolutionStatus) ?? "RECONSTRUCTED"
        referenceIDs = try container.decodeIfPresent([String].self, forKey: .referenceIDs) ?? []
    }
}

struct TranslationGoldExampleEntry: Codable, Sendable {
    let id: String
    let sourceText: String
    let results: [TranslationGoldExampleResult]
}

struct TranslationGoldExampleResult: Codable, Sendable {
    let script: String
    let fidelity: String
    let derivationKind: String
    let historicalStage: String
    let normalizedForm: String
    let diplomaticForm: String
    let glyphOutput: String
    let requestedVariant: String?
    let resolutionStatus: String
    let confidence: Double
    let notes: [String]
    let unresolvedTokens: [String]
    let provenance: [TranslationProvenanceEntry]
    let tokenBreakdown: [TranslationTokenBreakdown]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        script = try container.decode(String.self, forKey: .script)
        fidelity = try container.decode(String.self, forKey: .fidelity)
        derivationKind = try container.decodeIfPresent(String.self, forKey: .derivationKind) ?? "GOLD_EXAMPLE"
        historicalStage = try container.decode(String.self, forKey: .historicalStage)
        normalizedForm = try container.decode(String.self, forKey: .normalizedForm)
        diplomaticForm = try container.decode(String.self, forKey: .diplomaticForm)
        glyphOutput = try container.decodeIfPresent(String.self, forKey: .glyphOutput) ?? ""
        requestedVariant = try container.decodeIfPresent(String.self, forKey: .requestedVariant)
        resolutionStatus = try container.decodeIfPresent(String.self, forKey: .resolutionStatus) ?? "ATTESTED"
        confidence = try container.decodeIfPresent(Double.self, forKey: .confidence) ?? 1
        notes = try container.decodeIfPresent([String].self, forKey: .notes) ?? []
        unresolvedTokens = try container.decodeIfPresent([String].self, forKey: .unresolvedTokens) ?? []
        provenance = try container.decodeIfPresent([TranslationProvenanceEntry].self, forKey: .provenance) ?? []
        tokenBreakdown = try container.decodeIfPresent([TranslationTokenBreakdown].self, forKey: .tokenBreakdown) ?? []
    }
}
