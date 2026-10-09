//
//  AssetTranslationDatasetProvider.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import Foundation

/// Eager, immutable snapshot of all 14 strictly decoded translation assets.
/// A failed load throws before any partially initialized store can escape.
final class AssetTranslationDatasetProvider: HistoricalLexiconStore, RunicCorpusStore, EreborOrthographyStore, Sendable {
    private let datasetManifestCache: TranslationDatasetManifest
    private let oldNorseLexiconCache: [OldNorseLexiconEntry]
    private let protoNorseLexiconCache: [ProtoNorseLexiconEntry]
    private let paradigmTablesCache: ParadigmTablesData
    private let ereborTablesCache: EreborTablesData
    private let grammarRulesCache: GrammarRulesData
    private let nameAdaptationsCache: NameAdaptationsData
    private let fallbackTemplatesCache: FallbackTemplatesData
    private let sourceManifestCache: TranslationSourceManifest
    private let youngerPhraseTemplatesCache: [HistoricalPhraseTemplateEntry]
    private let elderAttestedFormsCache: [HistoricalPhraseTemplateEntry]
    private let runicCorpusReferencesCache: [RunicCorpusReferenceEntry]
    private let goldExamplesCache: [TranslationGoldExampleEntry]
    private let goldCorpusCache: TranslationGoldCorpus

    init(bundle: Bundle = .main, resourceDirectory: URL? = nil) throws {
        self.datasetManifestCache = try Self.read("dataset_manifest.json", bundle: bundle, resourceDirectory: resourceDirectory)
        self.oldNorseLexiconCache = try Self.read("old_norse_lexicon.json", bundle: bundle, resourceDirectory: resourceDirectory)
        self.protoNorseLexiconCache = try Self.read("proto_norse_lexicon.json", bundle: bundle, resourceDirectory: resourceDirectory)
        self.paradigmTablesCache = try Self.read("paradigm_tables.json", bundle: bundle, resourceDirectory: resourceDirectory)
        self.ereborTablesCache = try Self.read("erebor_tables.json", bundle: bundle, resourceDirectory: resourceDirectory)
        self.grammarRulesCache = try Self.read("grammar_rules.json", bundle: bundle, resourceDirectory: resourceDirectory)
        self.nameAdaptationsCache = try Self.read("name_adaptations.json", bundle: bundle, resourceDirectory: resourceDirectory)
        self.fallbackTemplatesCache = try Self.read("fallback_templates.json", bundle: bundle, resourceDirectory: resourceDirectory)
        self.sourceManifestCache = try Self.read("source_manifest.json", bundle: bundle, resourceDirectory: resourceDirectory)
        self.youngerPhraseTemplatesCache = try Self.read("younger_phrase_templates.json", bundle: bundle, resourceDirectory: resourceDirectory)
        self.elderAttestedFormsCache = try Self.read("elder_attested_forms.json", bundle: bundle, resourceDirectory: resourceDirectory)
        self.runicCorpusReferencesCache = try Self.read("runic_corpus_refs.json", bundle: bundle, resourceDirectory: resourceDirectory)
        self.goldExamplesCache = try Self.read("gold_examples.json", bundle: bundle, resourceDirectory: resourceDirectory)
        self.goldCorpusCache = try Self.read("gold_corpus.json", bundle: bundle, resourceDirectory: resourceDirectory)
        try self.validateReferences()
    }

    func datasetManifest() -> TranslationDatasetManifest {
        self.datasetManifestCache
    }

    func oldNorseLexicon() -> [OldNorseLexiconEntry] {
        self.oldNorseLexiconCache
    }

    func protoNorseLexicon() -> [ProtoNorseLexiconEntry] {
        self.protoNorseLexiconCache
    }

    func paradigmTables() -> ParadigmTablesData {
        self.paradigmTablesCache
    }

    func ereborTables() -> EreborTablesData {
        self.ereborTablesCache
    }

    func grammarRules() -> GrammarRulesData {
        self.grammarRulesCache
    }

    func nameAdaptations() -> NameAdaptationsData {
        self.nameAdaptationsCache
    }

    func fallbackTemplates() -> FallbackTemplatesData {
        self.fallbackTemplatesCache
    }

    func sourceManifest() -> TranslationSourceManifest {
        self.sourceManifestCache
    }

    func youngerPhraseTemplates() -> [HistoricalPhraseTemplateEntry] {
        self.youngerPhraseTemplatesCache
    }

    func elderAttestedForms() -> [HistoricalPhraseTemplateEntry] {
        self.elderAttestedFormsCache
    }

    func runicCorpusReferences() -> [RunicCorpusReferenceEntry] {
        self.runicCorpusReferencesCache
    }

    func goldExamples() -> [TranslationGoldExampleEntry] {
        self.goldExamplesCache
    }

    func goldCorpus() -> TranslationGoldCorpus {
        self.goldCorpusCache
    }

    private static func read<Value: Decodable>(_ fileName: String, bundle: Bundle, resourceDirectory: URL?) throws -> Value {
        let url = resourceDirectory.map { $0.appendingPathComponent(fileName) } ?? self.resourceURL(named: fileName, bundle: bundle)
        guard let url, FileManager.default.fileExists(atPath: url.path) else {
            throw TranslationDatasetError.missingResource(fileName)
        }
        return try JSONDecoder().decode(Value.self, from: Data(contentsOf: url))
    }

    private static func resourceURL(named fileName: String, bundle: Bundle) -> URL? {
        let name = URL(fileURLWithPath: fileName).deletingPathExtension().lastPathComponent
        let ext = URL(fileURLWithPath: fileName).pathExtension

        #if SWIFT_PACKAGE
            if let url = Bundle.module.url(forResource: name, withExtension: ext) {
                return url
            }
            if let url = Bundle.module.url(forResource: name, withExtension: ext, subdirectory: "Translation") {
                return url
            }
            if let url = Bundle.module.url(forResource: name, withExtension: ext, subdirectory: "Resources/Translation") {
                return url
            }
        #endif
        if let url = bundle.url(forResource: name, withExtension: ext, subdirectory: "Translation") {
            return url
        }
        if let url = bundle.url(forResource: name, withExtension: ext, subdirectory: "Resources/Translation") {
            return url
        }
        if let url = bundle.url(forResource: name, withExtension: ext) {
            return url
        }
        return nil
    }
}
