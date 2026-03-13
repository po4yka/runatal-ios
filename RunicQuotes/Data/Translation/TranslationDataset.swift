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
    func goldCorpus() -> TranslationGoldCorpus
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
    let sourceOfTruthPackage: String?
    let notes: [String]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try container.decode(String.self, forKey: .version)
        generatedAt = try container.decode(String.self, forKey: .generatedAt)
        generatedBy = try container.decode(String.self, forKey: .generatedBy)
        sourceOfTruthPackage = try container.decodeIfPresent(String.self, forKey: .sourceOfTruthPackage)
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
    let sourceWork: String?
    let citations: [String]
    let attestationStatusRaw: String
    let inventoryRaw: String
    let lemmaAuthorityID: String?
    let grammaticalClass: String?
    let historicalStage: String?
    let licenseNote: String?
    let regressionID: String?

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
        case sourceWork
        case citations
        case attestationStatusRaw = "attestationStatus"
        case inventoryRaw = "inventory"
        case lemmaAuthorityID = "lemmaAuthorityId"
        case grammaticalClass
        case historicalStage
        case licenseNote
        case regressionID = "regressionId"
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
        sourceWork = try container.decodeIfPresent(String.self, forKey: .sourceWork)
        citations = try container.decodeIfPresent([String].self, forKey: .citations) ?? []
        attestationStatusRaw = try container.decodeIfPresent(String.self, forKey: .attestationStatusRaw)
            ?? (strictEligible ? TranslationAttestationStatus.reconstructed.rawValue : TranslationAttestationStatus.fallback.rawValue)
        inventoryRaw = try container.decodeIfPresent(String.self, forKey: .inventoryRaw)
            ?? (strictEligible ? TranslationInventoryKind.approvedReconstruction.rawValue : TranslationInventoryKind.readableParaphrase.rawValue)
        lemmaAuthorityID = try container.decodeIfPresent(String.self, forKey: .lemmaAuthorityID)
        grammaticalClass = try container.decodeIfPresent(String.self, forKey: .grammaticalClass)
        historicalStage = try container.decodeIfPresent(String.self, forKey: .historicalStage)
        licenseNote = try container.decodeIfPresent(String.self, forKey: .licenseNote)
        regressionID = try container.decodeIfPresent(String.self, forKey: .regressionID)
    }

    var attestationStatus: TranslationAttestationStatus {
        TranslationAttestationStatus(rawValue: attestationStatusRaw) ?? .reconstructed
    }

    var inventory: TranslationInventoryKind {
        TranslationInventoryKind(rawValue: inventoryRaw) ?? .approvedReconstruction
    }
}

struct ProtoNorseLexiconEntry: Codable, Sendable {
    let id: String
    let english: String
    let form: String
    let partOfSpeech: String
    let strictEligible: Bool
    let sourceID: String
    let sourceWork: String?
    let citations: [String]
    let attestationStatusRaw: String
    let inventoryRaw: String
    let lemmaAuthorityID: String?
    let grammaticalClass: String?
    let historicalStage: String?
    let licenseNote: String?
    let regressionID: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case english
        case form
        case partOfSpeech
        case strictEligible
        case sourceID = "sourceId"
        case sourceWork
        case citations
        case attestationStatusRaw = "attestationStatus"
        case inventoryRaw = "inventory"
        case lemmaAuthorityID = "lemmaAuthorityId"
        case grammaticalClass
        case historicalStage
        case licenseNote
        case regressionID = "regressionId"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        english = try container.decode(String.self, forKey: .english)
        form = try container.decode(String.self, forKey: .form)
        partOfSpeech = try container.decode(String.self, forKey: .partOfSpeech)
        strictEligible = try container.decodeIfPresent(Bool.self, forKey: .strictEligible) ?? false
        sourceID = try container.decode(String.self, forKey: .sourceID)
        sourceWork = try container.decodeIfPresent(String.self, forKey: .sourceWork)
        citations = try container.decodeIfPresent([String].self, forKey: .citations) ?? []
        attestationStatusRaw = try container.decodeIfPresent(String.self, forKey: .attestationStatusRaw)
            ?? (strictEligible ? TranslationAttestationStatus.reconstructed.rawValue : TranslationAttestationStatus.fallback.rawValue)
        inventoryRaw = try container.decodeIfPresent(String.self, forKey: .inventoryRaw)
            ?? (strictEligible ? TranslationInventoryKind.approvedReconstruction.rawValue : TranslationInventoryKind.readableParaphrase.rawValue)
        lemmaAuthorityID = try container.decodeIfPresent(String.self, forKey: .lemmaAuthorityID)
        grammaticalClass = try container.decodeIfPresent(String.self, forKey: .grammaticalClass)
        historicalStage = try container.decodeIfPresent(String.self, forKey: .historicalStage)
        licenseNote = try container.decodeIfPresent(String.self, forKey: .licenseNote)
        regressionID = try container.decodeIfPresent(String.self, forKey: .regressionID)
    }

    var attestationStatus: TranslationAttestationStatus {
        TranslationAttestationStatus(rawValue: attestationStatusRaw) ?? .reconstructed
    }

    var inventory: TranslationInventoryKind {
        TranslationInventoryKind(rawValue: inventoryRaw) ?? .approvedReconstruction
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
    let auxiliaryMap: [String: String]
    let negationMap: [String: String]
    let multiwordExpressions: [String]
    let imperativeHints: [String]
    let englishFunctionWords: [String]

    init(
        removableWords: [String],
        prepositionMap: [String: String],
        interrogatives: [String],
        pronounMap: [String: String],
        auxiliaryMap: [String: String],
        negationMap: [String: String],
        multiwordExpressions: [String],
        imperativeHints: [String],
        englishFunctionWords: [String]
    ) {
        self.removableWords = removableWords
        self.prepositionMap = prepositionMap
        self.interrogatives = interrogatives
        self.pronounMap = pronounMap
        self.auxiliaryMap = auxiliaryMap
        self.negationMap = negationMap
        self.multiwordExpressions = multiwordExpressions
        self.imperativeHints = imperativeHints
        self.englishFunctionWords = englishFunctionWords
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        removableWords = try container.decodeIfPresent([String].self, forKey: .removableWords) ?? []
        prepositionMap = try container.decodeIfPresent([String: String].self, forKey: .prepositionMap) ?? [:]
        interrogatives = try container.decodeIfPresent([String].self, forKey: .interrogatives) ?? []
        pronounMap = try container.decodeIfPresent([String: String].self, forKey: .pronounMap) ?? [:]
        auxiliaryMap = try container.decodeIfPresent([String: String].self, forKey: .auxiliaryMap) ?? [:]
        negationMap = try container.decodeIfPresent([String: String].self, forKey: .negationMap) ?? [:]
        multiwordExpressions = try container.decodeIfPresent([String].self, forKey: .multiwordExpressions) ?? []
        imperativeHints = try container.decodeIfPresent([String].self, forKey: .imperativeHints) ?? []
        englishFunctionWords = try container.decodeIfPresent([String].self, forKey: .englishFunctionWords) ?? []
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
    let work: String?
    let license: String
    let licenseNote: String?
    let url: String
}

struct RunicCorpusReferenceEntry: Codable, Sendable {
    let id: String
    let sourceID: String
    let label: String
    let detail: String
    let url: String?
    let sourceWork: String?
    let attestationStatusRaw: String
    let historicalStage: String?
    let licenseNote: String?
    let regressionID: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case sourceID = "sourceId"
        case label
        case detail
        case url
        case sourceWork
        case attestationStatusRaw = "attestationStatus"
        case historicalStage
        case licenseNote
        case regressionID = "regressionId"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        sourceID = try container.decode(String.self, forKey: .sourceID)
        label = try container.decode(String.self, forKey: .label)
        detail = try container.decode(String.self, forKey: .detail)
        url = try container.decodeIfPresent(String.self, forKey: .url)
        sourceWork = try container.decodeIfPresent(String.self, forKey: .sourceWork)
        attestationStatusRaw = try container.decodeIfPresent(String.self, forKey: .attestationStatusRaw)
            ?? TranslationAttestationStatus.reconstructed.rawValue
        historicalStage = try container.decodeIfPresent(String.self, forKey: .historicalStage)
        licenseNote = try container.decodeIfPresent(String.self, forKey: .licenseNote)
        regressionID = try container.decodeIfPresent(String.self, forKey: .regressionID)
    }

    var attestationStatus: TranslationAttestationStatus {
        TranslationAttestationStatus(rawValue: attestationStatusRaw) ?? .reconstructed
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
    let inventoryRaw: String
    let attestationStatusRaw: String
    let sourceWork: String?
    let licenseNote: String?
    let regressionID: String?

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
        case inventoryRaw = "inventory"
        case attestationStatusRaw = "attestationStatus"
        case sourceWork
        case licenseNote
        case regressionID = "regressionId"
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
        inventoryRaw = try container.decodeIfPresent(String.self, forKey: .inventoryRaw)
            ?? TranslationInventoryKind.approvedReconstruction.rawValue
        attestationStatusRaw = try container.decodeIfPresent(String.self, forKey: .attestationStatusRaw)
            ?? TranslationAttestationStatus.reconstructed.rawValue
        sourceWork = try container.decodeIfPresent(String.self, forKey: .sourceWork)
        licenseNote = try container.decodeIfPresent(String.self, forKey: .licenseNote)
        regressionID = try container.decodeIfPresent(String.self, forKey: .regressionID)
    }

    var inventory: TranslationInventoryKind {
        TranslationInventoryKind(rawValue: inventoryRaw) ?? .approvedReconstruction
    }

    var attestationStatus: TranslationAttestationStatus {
        TranslationAttestationStatus(rawValue: attestationStatusRaw) ?? .reconstructed
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
    let regressionID: String?
    let results: [TranslationGoldExampleResult]

    private enum CodingKeys: String, CodingKey {
        case id
        case sourceText
        case regressionID = "regressionId"
        case results
    }
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
    let supportLevelRaw: String?
    let evidenceTierRaw: String?
    let attestationRefs: [String]
    let inputLanguageRaw: String?
    let userFacingWarnings: [String]

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
        supportLevelRaw = try container.decodeIfPresent(String.self, forKey: .supportLevelRaw)
        evidenceTierRaw = try container.decodeIfPresent(String.self, forKey: .evidenceTierRaw)
        attestationRefs = try container.decodeIfPresent([String].self, forKey: .attestationRefs) ?? []
        inputLanguageRaw = try container.decodeIfPresent(String.self, forKey: .inputLanguageRaw)
        userFacingWarnings = try container.decodeIfPresent([String].self, forKey: .userFacingWarnings) ?? []
    }

    private enum CodingKeys: String, CodingKey {
        case script
        case fidelity
        case derivationKind
        case historicalStage
        case normalizedForm
        case diplomaticForm
        case glyphOutput
        case requestedVariant
        case resolutionStatus
        case confidence
        case notes
        case unresolvedTokens
        case provenance
        case tokenBreakdown
        case supportLevelRaw = "supportLevel"
        case evidenceTierRaw = "evidenceTier"
        case attestationRefs
        case inputLanguageRaw = "inputLanguage"
        case userFacingWarnings
    }
}

struct TranslationGoldCorpus: Codable, Sendable {
    let benchmarks: [TranslationBenchmarkEntry]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        benchmarks = try container.decodeIfPresent([TranslationBenchmarkEntry].self, forKey: .benchmarks) ?? []
    }
}

struct TranslationBenchmarkEntry: Codable, Sendable {
    let id: String
    let category: String
    let sourceText: String
    let expectations: [TranslationBenchmarkExpectation]
    let notes: [String]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        category = try container.decode(String.self, forKey: .category)
        sourceText = try container.decode(String.self, forKey: .sourceText)
        expectations = try container.decodeIfPresent([TranslationBenchmarkExpectation].self, forKey: .expectations) ?? []
        notes = try container.decodeIfPresent([String].self, forKey: .notes) ?? []
    }
}

struct TranslationBenchmarkExpectation: Codable, Sendable {
    let script: String
    let fidelity: String
    let requestedVariant: String?
    let normalizedForm: String
    let diplomaticForm: String
    let glyphOutput: String
    let resolutionStatus: String
    let evidenceTier: String
    let supportLevel: String
    let attestationRefs: [String]
    let warningFragments: [String]
    let regressionID: String?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        script = try container.decode(String.self, forKey: .script)
        fidelity = try container.decode(String.self, forKey: .fidelity)
        requestedVariant = try container.decodeIfPresent(String.self, forKey: .requestedVariant)
        normalizedForm = try container.decode(String.self, forKey: .normalizedForm)
        diplomaticForm = try container.decode(String.self, forKey: .diplomaticForm)
        glyphOutput = try container.decode(String.self, forKey: .glyphOutput)
        resolutionStatus = try container.decode(String.self, forKey: .resolutionStatus)
        evidenceTier = try container.decode(String.self, forKey: .evidenceTier)
        supportLevel = try container.decode(String.self, forKey: .supportLevel)
        attestationRefs = try container.decodeIfPresent([String].self, forKey: .attestationRefs) ?? []
        warningFragments = try container.decodeIfPresent([String].self, forKey: .warningFragments) ?? []
        regressionID = try container.decodeIfPresent(String.self, forKey: .regressionID)
    }
}
