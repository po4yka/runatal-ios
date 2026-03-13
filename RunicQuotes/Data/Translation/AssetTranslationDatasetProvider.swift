//
//  AssetTranslationDatasetProvider.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import Foundation

/// Loads the offline translation datasets shipped with the app.
final class AssetTranslationDatasetProvider: HistoricalLexiconStore, RunicCorpusStore, EreborOrthographyStore, @unchecked Sendable {
    private let bundle: Bundle
    private let decoder: JSONDecoder

    private lazy var datasetManifestCache: TranslationDatasetManifest = read("dataset_manifest.json")
    private lazy var oldNorseLexiconCache: [OldNorseLexiconEntry] = read("old_norse_lexicon.json")
    private lazy var protoNorseLexiconCache: [ProtoNorseLexiconEntry] = read("proto_norse_lexicon.json")
    private lazy var paradigmTablesCache: ParadigmTablesData = read("paradigm_tables.json")
    private lazy var ereborTablesCache: EreborTablesData = read("erebor_tables.json")
    private lazy var grammarRulesCache: GrammarRulesData = read("grammar_rules.json")
    private lazy var nameAdaptationsCache: NameAdaptationsData = read("name_adaptations.json")
    private lazy var fallbackTemplatesCache: FallbackTemplatesData = read("fallback_templates.json")
    private lazy var sourceManifestCache: TranslationSourceManifest = read("source_manifest.json")
    private lazy var youngerPhraseTemplatesCache: [HistoricalPhraseTemplateEntry] = read("younger_phrase_templates.json")
    private lazy var elderAttestedFormsCache: [HistoricalPhraseTemplateEntry] = read("elder_attested_forms.json")
    private lazy var runicCorpusReferencesCache: [RunicCorpusReferenceEntry] = read("runic_corpus_refs.json")
    private lazy var goldExamplesCache: [TranslationGoldExampleEntry] = read("gold_examples.json")
    private lazy var goldCorpusCache: TranslationGoldCorpus = read("gold_corpus.json")

    init(bundle: Bundle = .main) {
        self.bundle = bundle
        self.decoder = JSONDecoder()
    }

    func datasetManifest() -> TranslationDatasetManifest {
        self.datasetManifestCache
    }

    func sourceManifest() -> TranslationSourceManifest {
        self.sourceManifestCache
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

    func grammarRules() -> GrammarRulesData {
        self.grammarRulesCache
    }

    func nameAdaptations() -> NameAdaptationsData {
        self.nameAdaptationsCache
    }

    func fallbackTemplates() -> FallbackTemplatesData {
        self.fallbackTemplatesCache
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

    func ereborTables() -> EreborTablesData {
        self.ereborTablesCache
    }

    /// Forces eager loading to reduce first-use latency.
    func warmUp() {
        _ = self.datasetManifestCache
        _ = self.oldNorseLexiconCache
        _ = self.protoNorseLexiconCache
        _ = self.paradigmTablesCache
        _ = self.ereborTablesCache
        _ = self.grammarRulesCache
        _ = self.nameAdaptationsCache
        _ = self.fallbackTemplatesCache
        _ = self.sourceManifestCache
        _ = self.youngerPhraseTemplatesCache
        _ = self.elderAttestedFormsCache
        _ = self.runicCorpusReferencesCache
        _ = self.goldExamplesCache
        _ = self.goldCorpusCache
    }

    private func read<T: Decodable>(_ fileName: String) -> T {
        guard let url = resourceURL(named: fileName) else {
            fatalError("Missing translation resource \(fileName)")
        }

        do {
            let data = try Data(contentsOf: url)
            return try self.decoder.decode(T.self, from: data)
        } catch {
            fatalError("Failed to decode translation resource \(fileName): \(error.localizedDescription)")
        }
    }

    private func resourceURL(named fileName: String) -> URL? {
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
