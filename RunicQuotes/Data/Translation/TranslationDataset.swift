//
//  TranslationDataset.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import Foundation

// MARK: - Store Protocols

protocol HistoricalLexiconStore: Sendable {
    func datasetManifest() -> TranslationDatasetManifest
    func sourceManifest() -> TranslationSourceManifest
    func oldNorseLexicon() -> [OldNorseLexiconEntry]
    func protoNorseLexicon() -> [ProtoNorseLexiconEntry]
    func paradigmTables() -> ParadigmTablesData
    func grammarRules() -> GrammarRulesData
    func nameAdaptations() -> NameAdaptationsData
    func fallbackTemplates() -> FallbackTemplatesData
}

protocol RunicCorpusStore: Sendable {
    func datasetManifest() -> TranslationDatasetManifest
    func sourceManifest() -> TranslationSourceManifest
    func youngerPhraseTemplates() -> [HistoricalPhraseTemplateEntry]
    func elderAttestedForms() -> [HistoricalPhraseTemplateEntry]
    func runicCorpusReferences() -> [RunicCorpusReferenceEntry]
    func goldExamples() -> [TranslationGoldExampleEntry]
    func goldCorpus() -> TranslationGoldCorpus
}

protocol EreborOrthographyStore: Sendable {
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
        self.version = try container.decode(String.self, forKey: .version)
        self.generatedAt = try container.decode(String.self, forKey: .generatedAt)
        self.generatedBy = try container.decode(String.self, forKey: .generatedBy)
        self.sourceOfTruthPackage = try container.decode(String.self, forKey: .sourceOfTruthPackage)
        self.notes = try container.decode([String].self, forKey: .notes)
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
    let nounForms: [String: String]?
    let objectCase: String?
    let requiresObject: Bool?
    let gender: String?
    let englishPluralForms: [String]?
    let adjectiveForms: [String: String]?
    let presentForms: [String: String]?
    let pastForms: [String: String]?
    let englishVerbForms: [String: EnglishVerbForm]?
    let inflectionSourceID: String?
    let inflectionCitations: [String]?
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
        case nounForms
        case objectCase
        case requiresObject
        case gender
        case englishPluralForms
        case adjectiveForms
        case presentForms
        case pastForms
        case englishVerbForms
        case inflectionSourceID = "inflectionSourceId"
        case inflectionCitations
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
        self.nounForms = try container.decodeIfPresent([String: String].self, forKey: .nounForms)
        self.objectCase = try container.decodeIfPresent(String.self, forKey: .objectCase)
        self.requiresObject = try container.decodeIfPresent(Bool.self, forKey: .requiresObject)
        self.gender = try container.decodeIfPresent(String.self, forKey: .gender)
        self.englishPluralForms = try container.decodeIfPresent([String].self, forKey: .englishPluralForms)
        self.adjectiveForms = try container.decodeIfPresent([String: String].self, forKey: .adjectiveForms)
        self.presentForms = try container.decodeIfPresent([String: String].self, forKey: .presentForms)
        self.pastForms = try container.decodeIfPresent([String: String].self, forKey: .pastForms)
        self.englishVerbForms = try container.decodeIfPresent([String: EnglishVerbForm].self, forKey: .englishVerbForms)
        self.inflectionSourceID = try container.decodeIfPresent(String.self, forKey: .inflectionSourceID)
        self.inflectionCitations = try container.decodeIfPresent([String].self, forKey: .inflectionCitations)
        self.strictEligible = try container.decode(Bool.self, forKey: .strictEligible)
        self.sourceID = try container.decode(String.self, forKey: .sourceID)
        self.sourceWork = try container.decode(String.self, forKey: .sourceWork)
        self.citations = try container.decode([String].self, forKey: .citations)
        self.attestationStatusRaw = try container.decodeRaw(TranslationAttestationStatus.self, forKey: .attestationStatusRaw)
        self.inventoryRaw = try container.decodeRaw(TranslationInventoryKind.self, forKey: .inventoryRaw)
        self.lemmaAuthorityID = try container.decodeIfPresent(String.self, forKey: .lemmaAuthorityID)
        self.grammaticalClass = try container.decodeIfPresent(String.self, forKey: .grammaticalClass)
        self.historicalStage = try container.decodeRaw(HistoricalStage.self, forKey: .historicalStage)
        self.licenseNote = try container.decode(String.self, forKey: .licenseNote)
        self.regressionID = try container.decode(String.self, forKey: .regressionID)
    }

    var attestationStatus: TranslationAttestationStatus {
        TranslationAttestationStatus(rawValue: self.attestationStatusRaw) ?? .reconstructed
    }

    var inventory: TranslationInventoryKind {
        TranslationInventoryKind(rawValue: self.inventoryRaw) ?? .readableParaphrase
    }
}

struct EnglishVerbForm: Codable, Sendable {
    let tense: String
    let agreements: [String]
}

struct EnglishPronounFeatures: Codable, Sendable {
    let person: Int
    let number: String
    let gender: String?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.person = try container.decode(Int.self, forKey: .person)
        self.number = try container.decode(String.self, forKey: .number)
        self.gender = try container.decodeIfPresent(String.self, forKey: .gender)
        guard (1 ... 3).contains(self.person), ["SINGULAR", "PLURAL"].contains(self.number),
              self.gender.map({ ["MASCULINE", "FEMININE", "NEUTER"].contains($0) }) ?? true
        else {
            throw DecodingError.dataCorruptedError(forKey: .person, in: container, debugDescription: "Unknown personal-pronoun features")
        }
    }
}

struct GovernedPreposition: Codable, Sendable {
    let lemma: String
    let grammaticalCase: String
    let sourceID: String
    let citations: [String]

    private enum CodingKeys: String, CodingKey {
        case lemma, grammaticalCase, citations
        case sourceID = "sourceId"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.lemma = try container.decode(String.self, forKey: .lemma)
        self.grammaticalCase = try container.decode(String.self, forKey: .grammaticalCase)
        self.sourceID = try container.decode(String.self, forKey: .sourceID)
        self.citations = try container.decode([String].self, forKey: .citations)
        guard ["NOMINATIVE", "ACCUSATIVE", "GENITIVE", "DATIVE"].contains(self.grammaticalCase) else {
            throw DecodingError.dataCorruptedError(forKey: .grammaticalCase, in: container, debugDescription: "Unknown preposition case")
        }
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
        self.id = try container.decode(String.self, forKey: .id)
        self.english = try container.decode(String.self, forKey: .english)
        self.form = try container.decode(String.self, forKey: .form)
        self.partOfSpeech = try container.decode(String.self, forKey: .partOfSpeech)
        self.strictEligible = try container.decode(Bool.self, forKey: .strictEligible)
        self.sourceID = try container.decode(String.self, forKey: .sourceID)
        self.sourceWork = try container.decode(String.self, forKey: .sourceWork)
        self.citations = try container.decode([String].self, forKey: .citations)
        self.attestationStatusRaw = try container.decodeRaw(TranslationAttestationStatus.self, forKey: .attestationStatusRaw)
        self.inventoryRaw = try container.decodeRaw(TranslationInventoryKind.self, forKey: .inventoryRaw)
        self.lemmaAuthorityID = try container.decodeIfPresent(String.self, forKey: .lemmaAuthorityID)
        self.grammaticalClass = try container.decodeIfPresent(String.self, forKey: .grammaticalClass)
        self.historicalStage = try container.decodeRaw(HistoricalStage.self, forKey: .historicalStage)
        self.licenseNote = try container.decode(String.self, forKey: .licenseNote)
        self.regressionID = try container.decode(String.self, forKey: .regressionID)
    }

    var attestationStatus: TranslationAttestationStatus {
        TranslationAttestationStatus(rawValue: self.attestationStatusRaw) ?? .reconstructed
    }

    var inventory: TranslationInventoryKind {
        TranslationInventoryKind(rawValue: self.inventoryRaw) ?? .readableParaphrase
    }
}

struct ParadigmTablesData: Codable, Sendable {
    let metadata: TranslationAssetMetadata
    let nounParadigms: [String: NounParadigm]
    let verbParadigms: [String: VerbParadigm]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.metadata = try container.decode(TranslationAssetMetadata.self, forKey: .metadata)
        self.nounParadigms = try container.decode([String: NounParadigm].self, forKey: .nounParadigms)
        self.verbParadigms = try container.decode([String: VerbParadigm].self, forKey: .verbParadigms)
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
    let metadata: TranslationAssetMetadata
    let phraseMappings: [EreborPhraseMappingEntry]
    let sequences: [String: String]
    let singleCharacters: [String: String]
    let longVowels: [String: String]
    let longConsonants: [String: String]
    let wordSeparator: String

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.metadata = try container.decode(TranslationAssetMetadata.self, forKey: .metadata)
        self.phraseMappings = try container.decode([EreborPhraseMappingEntry].self, forKey: .phraseMappings)
        self.sequences = try container.decode([String: String].self, forKey: .sequences)
        self.singleCharacters = try container.decode([String: String].self, forKey: .singleCharacters)
        self.longVowels = try container.decode([String: String].self, forKey: .longVowels)
        self.longConsonants = try container.decode([String: String].self, forKey: .longConsonants)
        self.wordSeparator = try container.decode(String.self, forKey: .wordSeparator)
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
        self.id = try container.decode(String.self, forKey: .id)
        self.sourceText = try container.decode(String.self, forKey: .sourceText)
        self.diplomaticForm = try container.decode(String.self, forKey: .diplomaticForm)
        self.glyphOutput = try container.decode(String.self, forKey: .glyphOutput)
        self.resolutionStatus = try container.decodeRaw(TranslationResolutionStatus.self, forKey: .resolutionStatus)
        self.notes = try container.decode([String].self, forKey: .notes)
        self.referenceIDs = try container.decode([String].self, forKey: .referenceIDs)
    }
}

struct GrammarRulesData: Codable, Sendable {
    let metadata: TranslationAssetMetadata
    let pronounFeatures: [String: EnglishPronounFeatures]
    let governedPrepositions: [String: GovernedPreposition]
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
        metadata: TranslationAssetMetadata,
        removableWords: [String],
        pronounFeatures: [String: EnglishPronounFeatures],
        governedPrepositions: [String: GovernedPreposition],
        prepositionMap: [String: String],
        interrogatives: [String],
        pronounMap: [String: String],
        auxiliaryMap: [String: String],
        negationMap: [String: String],
        multiwordExpressions: [String],
        imperativeHints: [String],
        englishFunctionWords: [String],
    ) {
        self.metadata = metadata
        self.pronounFeatures = pronounFeatures
        self.governedPrepositions = governedPrepositions
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
        self.metadata = try container.decode(TranslationAssetMetadata.self, forKey: .metadata)
        self.pronounFeatures = try container.decode([String: EnglishPronounFeatures].self, forKey: .pronounFeatures)
        self.governedPrepositions = try container.decode([String: GovernedPreposition].self, forKey: .governedPrepositions)
        self.removableWords = try container.decode([String].self, forKey: .removableWords)
        self.prepositionMap = try container.decode([String: String].self, forKey: .prepositionMap)
        self.interrogatives = try container.decode([String].self, forKey: .interrogatives)
        self.pronounMap = try container.decode([String: String].self, forKey: .pronounMap)
        self.auxiliaryMap = try container.decode([String: String].self, forKey: .auxiliaryMap)
        self.negationMap = try container.decode([String: String].self, forKey: .negationMap)
        self.multiwordExpressions = try container.decode([String].self, forKey: .multiwordExpressions)
        self.imperativeHints = try container.decode([String].self, forKey: .imperativeHints)
        self.englishFunctionWords = try container.decode([String].self, forKey: .englishFunctionWords)
    }
}

struct NameAdaptationsData: Codable, Sendable {
    let metadata: TranslationAssetMetadata
    let names: [String: String]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.metadata = try container.decode(TranslationAssetMetadata.self, forKey: .metadata)
        self.names = try container.decode([String: String].self, forKey: .names)
    }
}

struct FallbackTemplatesData: Codable, Sendable {
    let metadata: TranslationAssetMetadata
    let synonyms: [String: String]
    let paraphrasesByStage: [String: [String: String]]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.metadata = try container.decode(TranslationAssetMetadata.self, forKey: .metadata)
        self.synonyms = try container.decode([String: String].self, forKey: .synonyms)
        self.paraphrasesByStage = try container.decode([String: [String: String]].self, forKey: .paraphrasesByStage)
    }
}

struct TranslationSourceManifest: Codable, Sendable {
    let sources: [TranslationSourceEntry]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.sources = try container.decode([TranslationSourceEntry].self, forKey: .sources)
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
        self.id = try container.decode(String.self, forKey: .id)
        self.sourceID = try container.decode(String.self, forKey: .sourceID)
        self.label = try container.decode(String.self, forKey: .label)
        self.detail = try container.decode(String.self, forKey: .detail)
        self.url = try container.decodeIfPresent(String.self, forKey: .url)
        self.sourceWork = try container.decode(String.self, forKey: .sourceWork)
        self.attestationStatusRaw = try container.decodeRaw(TranslationAttestationStatus.self, forKey: .attestationStatusRaw)
        self.historicalStage = try container.decodeRaw(HistoricalStage.self, forKey: .historicalStage)
        self.licenseNote = try container.decode(String.self, forKey: .licenseNote)
        self.regressionID = try container.decode(String.self, forKey: .regressionID)
    }

    var attestationStatus: TranslationAttestationStatus {
        TranslationAttestationStatus(rawValue: self.attestationStatusRaw) ?? .reconstructed
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
        self.id = try container.decode(String.self, forKey: .id)
        self.script = try container.decodeScript(forKey: .script)
        self.fidelity = try container.decodeRaw(TranslationFidelity.self, forKey: .fidelity)
        self.derivationKind = try container.decodeRaw(TranslationDerivationKind.self, forKey: .derivationKind)
        self.historicalStage = try container.decodeRaw(HistoricalStage.self, forKey: .historicalStage)
        self.sourceText = try container.decode(String.self, forKey: .sourceText)
        self.normalizedForm = try container.decode(String.self, forKey: .normalizedForm)
        self.diplomaticForm = try container.decode(String.self, forKey: .diplomaticForm)
        self.resolutionStatus = try container.decodeRaw(TranslationResolutionStatus.self, forKey: .resolutionStatus)
        self.notes = try container.decode([String].self, forKey: .notes)
        self.referenceIDs = try container.decode([String].self, forKey: .referenceIDs)
        self.tokenBreakdown = try container.decode([HistoricalTemplateTokenEntry].self, forKey: .tokenBreakdown)
        self.inventoryRaw = try container.decodeRaw(TranslationInventoryKind.self, forKey: .inventoryRaw)
        self.attestationStatusRaw = try container.decodeRaw(TranslationAttestationStatus.self, forKey: .attestationStatusRaw)
        self.sourceWork = try container.decode(String.self, forKey: .sourceWork)
        self.licenseNote = try container.decode(String.self, forKey: .licenseNote)
        self.regressionID = try container.decode(String.self, forKey: .regressionID)
    }

    var inventory: TranslationInventoryKind {
        TranslationInventoryKind(rawValue: self.inventoryRaw) ?? .readableParaphrase
    }

    var attestationStatus: TranslationAttestationStatus {
        TranslationAttestationStatus(rawValue: self.attestationStatusRaw) ?? .reconstructed
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
        self.sourceToken = try container.decode(String.self, forKey: .sourceToken)
        self.normalizedToken = try container.decode(String.self, forKey: .normalizedToken)
        self.diplomaticToken = try container.decode(String.self, forKey: .diplomaticToken)
        self.resolutionStatus = try container.decodeRaw(TranslationResolutionStatus.self, forKey: .resolutionStatus)
        self.referenceIDs = try container.decode([String].self, forKey: .referenceIDs)
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
    let inventory: TranslationInventoryKind
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
        self.inventory = try container.decode(TranslationInventoryKind.self, forKey: .inventory)
        self.script = try container.decodeScript(forKey: .script)
        self.fidelity = try container.decodeRaw(TranslationFidelity.self, forKey: .fidelity)
        self.derivationKind = try container.decodeRaw(TranslationDerivationKind.self, forKey: .derivationKind)
        self.historicalStage = try container.decodeRaw(HistoricalStage.self, forKey: .historicalStage)
        self.normalizedForm = try container.decode(String.self, forKey: .normalizedForm)
        self.diplomaticForm = try container.decode(String.self, forKey: .diplomaticForm)
        self.glyphOutput = try container.decode(String.self, forKey: .glyphOutput)
        self.requestedVariant = try container.decodeIfPresent(String.self, forKey: .requestedVariant)
        self.resolutionStatus = try container.decodeRaw(TranslationResolutionStatus.self, forKey: .resolutionStatus)
        self.confidence = try container.decodeConfidence(forKey: .confidence)
        self.notes = try container.decode([String].self, forKey: .notes)
        self.unresolvedTokens = try container.decode([String].self, forKey: .unresolvedTokens)
        self.provenance = try container.decode([TranslationProvenanceEntry].self, forKey: .provenance)
        self.tokenBreakdown = try container.decode([TranslationTokenBreakdown].self, forKey: .tokenBreakdown)
        self.supportLevelRaw = try container.decodeRaw(TranslationSupportLevel.self, forKey: .supportLevelRaw)
        self.evidenceTierRaw = try container.decodeRaw(TranslationEvidenceTier.self, forKey: .evidenceTierRaw)
        self.attestationRefs = try container.decode([String].self, forKey: .attestationRefs)
        self.inputLanguageRaw = try container.decodeRaw(TranslationSourceLanguage.self, forKey: .inputLanguageRaw)
        self.userFacingWarnings = try container.decode([String].self, forKey: .userFacingWarnings)
    }

    private enum CodingKeys: String, CodingKey {
        case inventory
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
        self.benchmarks = try container.decode([TranslationBenchmarkEntry].self, forKey: .benchmarks)
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
        self.id = try container.decode(String.self, forKey: .id)
        self.category = try container.decode(String.self, forKey: .category)
        self.sourceText = try container.decode(String.self, forKey: .sourceText)
        self.expectations = try container.decode([TranslationBenchmarkExpectation].self, forKey: .expectations)
        self.notes = try container.decode([String].self, forKey: .notes)
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
        self.script = try container.decodeScript(forKey: .script)
        self.fidelity = try container.decodeRaw(TranslationFidelity.self, forKey: .fidelity)
        self.requestedVariant = try container.decodeIfPresent(String.self, forKey: .requestedVariant)
        self.normalizedForm = try container.decode(String.self, forKey: .normalizedForm)
        self.diplomaticForm = try container.decode(String.self, forKey: .diplomaticForm)
        self.glyphOutput = try container.decode(String.self, forKey: .glyphOutput)
        self.resolutionStatus = try container.decodeRaw(TranslationResolutionStatus.self, forKey: .resolutionStatus)
        self.evidenceTier = try container.decodeRaw(TranslationEvidenceTier.self, forKey: .evidenceTier)
        self.supportLevel = try container.decodeRaw(TranslationSupportLevel.self, forKey: .supportLevel)
        self.attestationRefs = try container.decode([String].self, forKey: .attestationRefs)
        self.warningFragments = try container.decode([String].self, forKey: .warningFragments)
        self.regressionID = try container.decode(String.self, forKey: .regressionID)
    }
}
