//
//  AssetTranslationDatasetProvider.swift
//  RunicQuotes
//
//  Created by Codex on 2026-03-13.
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

    func datasetManifest() -> TranslationDatasetManifest { datasetManifestCache }
    func sourceManifest() -> TranslationSourceManifest { sourceManifestCache }
    func oldNorseLexicon() -> [OldNorseLexiconEntry] { oldNorseLexiconCache }
    func protoNorseLexicon() -> [ProtoNorseLexiconEntry] { protoNorseLexiconCache }
    func paradigmTables() -> ParadigmTablesData { paradigmTablesCache }
    func grammarRules() -> GrammarRulesData { grammarRulesCache }
    func nameAdaptations() -> NameAdaptationsData { nameAdaptationsCache }
    func fallbackTemplates() -> FallbackTemplatesData { fallbackTemplatesCache }
    func youngerPhraseTemplates() -> [HistoricalPhraseTemplateEntry] { youngerPhraseTemplatesCache }
    func elderAttestedForms() -> [HistoricalPhraseTemplateEntry] { elderAttestedFormsCache }
    func runicCorpusReferences() -> [RunicCorpusReferenceEntry] { runicCorpusReferencesCache }
    func goldExamples() -> [TranslationGoldExampleEntry] { goldExamplesCache }
    func goldCorpus() -> TranslationGoldCorpus { goldCorpusCache }
    func ereborTables() -> EreborTablesData { ereborTablesCache }

    /// Forces eager loading to reduce first-use latency.
    func warmUp() {
        _ = datasetManifestCache
        _ = oldNorseLexiconCache
        _ = protoNorseLexiconCache
        _ = paradigmTablesCache
        _ = ereborTablesCache
        _ = grammarRulesCache
        _ = nameAdaptationsCache
        _ = fallbackTemplatesCache
        _ = sourceManifestCache
        _ = youngerPhraseTemplatesCache
        _ = elderAttestedFormsCache
        _ = runicCorpusReferencesCache
        _ = goldExamplesCache
        _ = goldCorpusCache
    }

    private func read<T: Decodable>(_ fileName: String) -> T {
        guard let url = resourceURL(named: fileName) else {
            fatalError("Missing translation resource \(fileName)")
        }

        do {
            let data = try Data(contentsOf: url)
            return try decoder.decode(T.self, from: data)
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
