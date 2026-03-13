//
//  TranslationDataset.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
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

struct TranslationDatasetManifest: Codable {
    let version: String
    let generatedAt: String
    let generatedBy: String
    let sourceOfTruthPackage: String?
    let notes: [String]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.version = try container.decode(String.self, forKey: .version)
        self.generatedAt = try container.decode(String.self, forKey: .generatedAt)
        self.generatedBy = try container.decode(String.self, forKey: .generatedBy)
        self.sourceOfTruthPackage = try container.decodeIfPresent(String.self, forKey: .sourceOfTruthPackage)
        self.notes = try container.decodeIfPresent([String].self, forKey: .notes) ?? []
    }
}

struct OldNorseLexiconEntry: Codable {
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
        self.id = try container.decode(String.self, forKey: .id)
        self.english = try container.decode(String.self, forKey: .english)
        self.partOfSpeech = try container.decode(String.self, forKey: .partOfSpeech)
        self.lemma = try container.decode(String.self, forKey: .lemma)
        self.paradigmID = try container.decodeIfPresent(String.self, forKey: .paradigmID)
        self.present3sg = try container.decodeIfPresent(String.self, forKey: .present3sg)
        self.past3sg = try container.decodeIfPresent(String.self, forKey: .past3sg)
        self.pluralForm = try container.decodeIfPresent(String.self, forKey: .pluralForm)
        self.dativePhrase = try container.decodeIfPresent(String.self, forKey: .dativePhrase)
        self.strictEligible = try container.decodeIfPresent(Bool.self, forKey: .strictEligible) ?? true
        self.sourceID = try container.decode(String.self, forKey: .sourceID)
        self.sourceWork = try container.decodeIfPresent(String.self, forKey: .sourceWork)
        self.citations = try container.decodeIfPresent([String].self, forKey: .citations) ?? []
        self.attestationStatusRaw = try container.decodeIfPresent(String.self, forKey: .attestationStatusRaw)
            ?? (self.strictEligible ? TranslationAttestationStatus.reconstructed.rawValue : TranslationAttestationStatus.fallback.rawValue)
        self.inventoryRaw = try container.decodeIfPresent(String.self, forKey: .inventoryRaw)
            ?? (self.strictEligible ? TranslationInventoryKind.approvedReconstruction.rawValue : TranslationInventoryKind.readableParaphrase.rawValue)
        self.lemmaAuthorityID = try container.decodeIfPresent(String.self, forKey: .lemmaAuthorityID)
        self.grammaticalClass = try container.decodeIfPresent(String.self, forKey: .grammaticalClass)
        self.historicalStage = try container.decodeIfPresent(String.self, forKey: .historicalStage)
        self.licenseNote = try container.decodeIfPresent(String.self, forKey: .licenseNote)
        self.regressionID = try container.decodeIfPresent(String.self, forKey: .regressionID)
    }

    var attestationStatus: TranslationAttestationStatus {
        TranslationAttestationStatus(rawValue: self.attestationStatusRaw) ?? .reconstructed
    }

    var inventory: TranslationInventoryKind {
        TranslationInventoryKind(rawValue: self.inventoryRaw) ?? .approvedReconstruction
    }
}

struct ProtoNorseLexiconEntry: Codable {
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
        self.id = try container.decode(String.self, forKey: .id)
        self.english = try container.decode(String.self, forKey: .english)
        self.form = try container.decode(String.self, forKey: .form)
        self.partOfSpeech = try container.decode(String.self, forKey: .partOfSpeech)
        self.strictEligible = try container.decodeIfPresent(Bool.self, forKey: .strictEligible) ?? false
        self.sourceID = try container.decode(String.self, forKey: .sourceID)
        self.sourceWork = try container.decodeIfPresent(String.self, forKey: .sourceWork)
        self.citations = try container.decodeIfPresent([String].self, forKey: .citations) ?? []
        self.attestationStatusRaw = try container.decodeIfPresent(String.self, forKey: .attestationStatusRaw)
            ?? (self.strictEligible ? TranslationAttestationStatus.reconstructed.rawValue : TranslationAttestationStatus.fallback.rawValue)
        self.inventoryRaw = try container.decodeIfPresent(String.self, forKey: .inventoryRaw)
            ?? (self.strictEligible ? TranslationInventoryKind.approvedReconstruction.rawValue : TranslationInventoryKind.readableParaphrase.rawValue)
        self.lemmaAuthorityID = try container.decodeIfPresent(String.self, forKey: .lemmaAuthorityID)
        self.grammaticalClass = try container.decodeIfPresent(String.self, forKey: .grammaticalClass)
        self.historicalStage = try container.decodeIfPresent(String.self, forKey: .historicalStage)
        self.licenseNote = try container.decodeIfPresent(String.self, forKey: .licenseNote)
        self.regressionID = try container.decodeIfPresent(String.self, forKey: .regressionID)
    }

    var attestationStatus: TranslationAttestationStatus {
        TranslationAttestationStatus(rawValue: self.attestationStatusRaw) ?? .reconstructed
    }

    var inventory: TranslationInventoryKind {
        TranslationInventoryKind(rawValue: self.inventoryRaw) ?? .approvedReconstruction
    }
}

struct ParadigmTablesData: Codable {
    let nounParadigms: [String: NounParadigm]
    let verbParadigms: [String: VerbParadigm]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.nounParadigms = try container.decodeIfPresent([String: NounParadigm].self, forKey: .nounParadigms) ?? [:]
        self.verbParadigms = try container.decodeIfPresent([String: VerbParadigm].self, forKey: .verbParadigms) ?? [:]
    }
}

struct NounParadigm: Codable {
    let nominativeSingularSuffix: String
    let pluralSuffix: String
}

struct VerbParadigm: Codable {
    let thirdPersonPresentSuffix: String
    let thirdPersonPastSuffix: String
}

struct EreborTablesData: Codable {
    let phraseMappings: [EreborPhraseMappingEntry]
    let sequences: [String: String]
    let singleCharacters: [String: String]
    let longVowels: [String: String]
    let longConsonants: [String: String]
    let wordSeparator: String

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.phraseMappings = try container.decodeIfPresent([EreborPhraseMappingEntry].self, forKey: .phraseMappings) ?? []
        self.sequences = try container.decodeIfPresent([String: String].self, forKey: .sequences) ?? [:]
        self.singleCharacters = try container.decodeIfPresent([String: String].self, forKey: .singleCharacters) ?? [:]
        self.longVowels = try container.decodeIfPresent([String: String].self, forKey: .longVowels) ?? [:]
        self.longConsonants = try container.decodeIfPresent([String: String].self, forKey: .longConsonants) ?? [:]
        self.wordSeparator = try container.decodeIfPresent(String.self, forKey: .wordSeparator) ?? "·"
    }
}

struct EreborPhraseMappingEntry: Codable {
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
        self.id = try container.decode(String.self, forKey: .id)
        self.sourceText = try container.decode(String.self, forKey: .sourceText)
        self.diplomaticForm = try container.decode(String.self, forKey: .diplomaticForm)
        self.glyphOutput = try container.decodeIfPresent(String.self, forKey: .glyphOutput) ?? ""
        self.resolutionStatus = try container.decodeIfPresent(String.self, forKey: .resolutionStatus) ?? "ATTESTED"
        self.notes = try container.decodeIfPresent([String].self, forKey: .notes) ?? []
        self.referenceIDs = try container.decodeIfPresent([String].self, forKey: .referenceIDs) ?? []
    }
}

struct GrammarRulesData: Codable {
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
        englishFunctionWords: [String],
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
        self.removableWords = try container.decodeIfPresent([String].self, forKey: .removableWords) ?? []
        self.prepositionMap = try container.decodeIfPresent([String: String].self, forKey: .prepositionMap) ?? [:]
        self.interrogatives = try container.decodeIfPresent([String].self, forKey: .interrogatives) ?? []
        self.pronounMap = try container.decodeIfPresent([String: String].self, forKey: .pronounMap) ?? [:]
        self.auxiliaryMap = try container.decodeIfPresent([String: String].self, forKey: .auxiliaryMap) ?? [:]
        self.negationMap = try container.decodeIfPresent([String: String].self, forKey: .negationMap) ?? [:]
        self.multiwordExpressions = try container.decodeIfPresent([String].self, forKey: .multiwordExpressions) ?? []
        self.imperativeHints = try container.decodeIfPresent([String].self, forKey: .imperativeHints) ?? []
        self.englishFunctionWords = try container.decodeIfPresent([String].self, forKey: .englishFunctionWords) ?? []
    }
}

struct NameAdaptationsData: Codable {
    let names: [String: String]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.names = try container.decodeIfPresent([String: String].self, forKey: .names) ?? [:]
    }
}

struct FallbackTemplatesData: Codable {
    let synonyms: [String: String]
    let paraphrases: [String: String]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.synonyms = try container.decodeIfPresent([String: String].self, forKey: .synonyms) ?? [:]
        self.paraphrases = try container.decodeIfPresent([String: String].self, forKey: .paraphrases) ?? [:]
    }
}

struct TranslationSourceManifest: Codable {
    let sources: [TranslationSourceEntry]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.sources = try container.decodeIfPresent([TranslationSourceEntry].self, forKey: .sources) ?? []
    }
}

struct TranslationSourceEntry: Codable {
    let id: String
    let name: String
    let role: String
    let work: String?
    let license: String
    let licenseNote: String?
    let url: String
}

struct RunicCorpusReferenceEntry: Codable {
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
        self.id = try container.decode(String.self, forKey: .id)
        self.sourceID = try container.decode(String.self, forKey: .sourceID)
        self.label = try container.decode(String.self, forKey: .label)
        self.detail = try container.decode(String.self, forKey: .detail)
        self.url = try container.decodeIfPresent(String.self, forKey: .url)
        self.sourceWork = try container.decodeIfPresent(String.self, forKey: .sourceWork)
        self.attestationStatusRaw = try container.decodeIfPresent(String.self, forKey: .attestationStatusRaw)
            ?? TranslationAttestationStatus.reconstructed.rawValue
        self.historicalStage = try container.decodeIfPresent(String.self, forKey: .historicalStage)
        self.licenseNote = try container.decodeIfPresent(String.self, forKey: .licenseNote)
        self.regressionID = try container.decodeIfPresent(String.self, forKey: .regressionID)
    }

    var attestationStatus: TranslationAttestationStatus {
        TranslationAttestationStatus(rawValue: self.attestationStatusRaw) ?? .reconstructed
    }
}

struct HistoricalPhraseTemplateEntry: Codable {
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
        self.id = try container.decode(String.self, forKey: .id)
        self.script = try container.decode(String.self, forKey: .script)
        self.fidelity = try container.decode(String.self, forKey: .fidelity)
        self.derivationKind = try container.decode(String.self, forKey: .derivationKind)
        self.historicalStage = try container.decode(String.self, forKey: .historicalStage)
        self.sourceText = try container.decode(String.self, forKey: .sourceText)
        self.normalizedForm = try container.decode(String.self, forKey: .normalizedForm)
        self.diplomaticForm = try container.decode(String.self, forKey: .diplomaticForm)
        self.resolutionStatus = try container.decodeIfPresent(String.self, forKey: .resolutionStatus) ?? "RECONSTRUCTED"
        self.notes = try container.decodeIfPresent([String].self, forKey: .notes) ?? []
        self.referenceIDs = try container.decodeIfPresent([String].self, forKey: .referenceIDs) ?? []
        self.tokenBreakdown = try container.decodeIfPresent([HistoricalTemplateTokenEntry].self, forKey: .tokenBreakdown) ?? []
        self.inventoryRaw = try container.decodeIfPresent(String.self, forKey: .inventoryRaw)
            ?? TranslationInventoryKind.approvedReconstruction.rawValue
        self.attestationStatusRaw = try container.decodeIfPresent(String.self, forKey: .attestationStatusRaw)
            ?? TranslationAttestationStatus.reconstructed.rawValue
        self.sourceWork = try container.decodeIfPresent(String.self, forKey: .sourceWork)
        self.licenseNote = try container.decodeIfPresent(String.self, forKey: .licenseNote)
        self.regressionID = try container.decodeIfPresent(String.self, forKey: .regressionID)
    }

    var inventory: TranslationInventoryKind {
        TranslationInventoryKind(rawValue: self.inventoryRaw) ?? .approvedReconstruction
    }

    var attestationStatus: TranslationAttestationStatus {
        TranslationAttestationStatus(rawValue: self.attestationStatusRaw) ?? .reconstructed
    }
}

struct HistoricalTemplateTokenEntry: Codable {
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
        self.sourceToken = try container.decode(String.self, forKey: .sourceToken)
        self.normalizedToken = try container.decode(String.self, forKey: .normalizedToken)
        self.diplomaticToken = try container.decode(String.self, forKey: .diplomaticToken)
        self.resolutionStatus = try container.decodeIfPresent(String.self, forKey: .resolutionStatus) ?? "RECONSTRUCTED"
        self.referenceIDs = try container.decodeIfPresent([String].self, forKey: .referenceIDs) ?? []
    }
}

struct TranslationGoldExampleEntry: Codable {
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

struct TranslationGoldExampleResult: Codable {
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
        self.script = try container.decode(String.self, forKey: .script)
        self.fidelity = try container.decode(String.self, forKey: .fidelity)
        self.derivationKind = try container.decodeIfPresent(String.self, forKey: .derivationKind) ?? "GOLD_EXAMPLE"
        self.historicalStage = try container.decode(String.self, forKey: .historicalStage)
        self.normalizedForm = try container.decode(String.self, forKey: .normalizedForm)
        self.diplomaticForm = try container.decode(String.self, forKey: .diplomaticForm)
        self.glyphOutput = try container.decodeIfPresent(String.self, forKey: .glyphOutput) ?? ""
        self.requestedVariant = try container.decodeIfPresent(String.self, forKey: .requestedVariant)
        self.resolutionStatus = try container.decodeIfPresent(String.self, forKey: .resolutionStatus) ?? "ATTESTED"
        self.confidence = try container.decodeIfPresent(Double.self, forKey: .confidence) ?? 1
        self.notes = try container.decodeIfPresent([String].self, forKey: .notes) ?? []
        self.unresolvedTokens = try container.decodeIfPresent([String].self, forKey: .unresolvedTokens) ?? []
        self.provenance = try container.decodeIfPresent([TranslationProvenanceEntry].self, forKey: .provenance) ?? []
        self.tokenBreakdown = try container.decodeIfPresent([TranslationTokenBreakdown].self, forKey: .tokenBreakdown) ?? []
        self.supportLevelRaw = try container.decodeIfPresent(String.self, forKey: .supportLevelRaw)
        self.evidenceTierRaw = try container.decodeIfPresent(String.self, forKey: .evidenceTierRaw)
        self.attestationRefs = try container.decodeIfPresent([String].self, forKey: .attestationRefs) ?? []
        self.inputLanguageRaw = try container.decodeIfPresent(String.self, forKey: .inputLanguageRaw)
        self.userFacingWarnings = try container.decodeIfPresent([String].self, forKey: .userFacingWarnings) ?? []
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

struct TranslationGoldCorpus: Codable {
    let benchmarks: [TranslationBenchmarkEntry]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.benchmarks = try container.decodeIfPresent([TranslationBenchmarkEntry].self, forKey: .benchmarks) ?? []
    }
}

struct TranslationBenchmarkEntry: Codable {
    let id: String
    let category: String
    let sourceText: String
    let expectations: [TranslationBenchmarkExpectation]
    let notes: [String]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.category = try container.decode(String.self, forKey: .category)
        self.sourceText = try container.decode(String.self, forKey: .sourceText)
        self.expectations = try container.decodeIfPresent([TranslationBenchmarkExpectation].self, forKey: .expectations) ?? []
        self.notes = try container.decodeIfPresent([String].self, forKey: .notes) ?? []
    }
}

struct TranslationBenchmarkExpectation: Codable {
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
        self.script = try container.decode(String.self, forKey: .script)
        self.fidelity = try container.decode(String.self, forKey: .fidelity)
        self.requestedVariant = try container.decodeIfPresent(String.self, forKey: .requestedVariant)
        self.normalizedForm = try container.decode(String.self, forKey: .normalizedForm)
        self.diplomaticForm = try container.decode(String.self, forKey: .diplomaticForm)
        self.glyphOutput = try container.decode(String.self, forKey: .glyphOutput)
        self.resolutionStatus = try container.decode(String.self, forKey: .resolutionStatus)
        self.evidenceTier = try container.decode(String.self, forKey: .evidenceTier)
        self.supportLevel = try container.decode(String.self, forKey: .supportLevel)
        self.attestationRefs = try container.decodeIfPresent([String].self, forKey: .attestationRefs) ?? []
        self.warningFragments = try container.decodeIfPresent([String].self, forKey: .warningFragments) ?? []
        self.regressionID = try container.decodeIfPresent(String.self, forKey: .regressionID)
    }
}
