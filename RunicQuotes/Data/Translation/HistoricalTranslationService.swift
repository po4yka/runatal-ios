//
//  HistoricalTranslationService.swift
//  RunicQuotes
//
//  Created by Codex on 2026-03-13.
//

import Foundation

// swiftlint:disable file_length function_body_length function_parameter_count

// MARK: - Service

protocol TranslationEngine {
    var script: RunicScript { get }
    var engineVersion: String { get }
    var datasetVersion: String { get }
    func translate(_ request: TranslationRequest) -> TranslationResult
}

/// Structured offline historical translation and Erebor transcription service.
final class HistoricalTranslationService: @unchecked Sendable {
    private let assetProvider: AssetTranslationDatasetProvider?
    private let engineFactory: TranslationEngineFactory

    init(
        lexiconStore: HistoricalLexiconStore,
        runicCorpusStore: RunicCorpusStore,
        ereborStore: EreborOrthographyStore
    ) {
        assetProvider = nil
        engineFactory = TranslationEngineFactory(
            elderEngine: ElderFutharkTranslationEngine(
                lexiconStore: lexiconStore,
                runicCorpusStore: runicCorpusStore
            ),
            youngerEngine: YoungerFutharkTranslationEngine(
                lexiconStore: lexiconStore,
                runicCorpusStore: runicCorpusStore
            ),
            cirthEngine: EreborCirthTranslationEngine(
                runicCorpusStore: runicCorpusStore,
                ereborStore: ereborStore
            )
        )
    }

    init(datasetProvider: AssetTranslationDatasetProvider = AssetTranslationDatasetProvider()) {
        assetProvider = datasetProvider
        engineFactory = TranslationEngineFactory(
            elderEngine: ElderFutharkTranslationEngine(
                lexiconStore: datasetProvider,
                runicCorpusStore: datasetProvider
            ),
            youngerEngine: YoungerFutharkTranslationEngine(
                lexiconStore: datasetProvider,
                runicCorpusStore: datasetProvider
            ),
            cirthEngine: EreborCirthTranslationEngine(
                runicCorpusStore: datasetProvider,
                ereborStore: datasetProvider
            )
        )
    }

    var versionSignature: String {
        [
            engineFactory.create(.elder).engineVersion,
            engineFactory.create(.younger).engineVersion,
            engineFactory.create(.cirth).engineVersion
        ].joined(separator: "|")
    }

    var datasetVersion: String {
        engineFactory.create(.elder).datasetVersion
    }

    func warmUp() {
        assetProvider?.warmUp()
    }

    func translate(
        text: String,
        script: RunicScript,
        fidelity: TranslationFidelity = .default,
        youngerVariant: YoungerFutharkVariant = .default
    ) -> TranslationResult {
        let request = TranslationRequest(
            sourceText: text,
            script: script,
            fidelity: fidelity,
            youngerVariant: youngerVariant
        )
        return engineFactory.create(script).translate(request)
    }

    func translateAllAvailable(
        text: String,
        fidelity: TranslationFidelity = .default,
        youngerVariant: YoungerFutharkVariant = .default
    ) -> [TranslationResult] {
        RunicScript.allCases.map {
            translate(text: text, script: $0, fidelity: fidelity, youngerVariant: youngerVariant)
        }
    }
}

private struct TranslationEngineFactory {
    let elderEngine: ElderFutharkTranslationEngine
    let youngerEngine: YoungerFutharkTranslationEngine
    let cirthEngine: EreborCirthTranslationEngine

    func create(_ script: RunicScript) -> any TranslationEngine {
        switch script {
        case .elder:
            return elderEngine
        case .younger:
            return youngerEngine
        case .cirth:
            return cirthEngine
        }
    }
}

// MARK: - Engines

private struct YoungerFutharkTranslationEngine: TranslationEngine {
    let script: RunicScript = .younger
    let engineVersion = "yf-translation-v3"

    private let parser = EnglishSyntaxParser()
    private let sourceCatalog: HistoricalSourceCatalog
    private let goldExampleResolver: TranslationGoldExampleResolver
    private let phraseTemplateResolver: RunicPhraseTemplateResolver
    private let lexiconLookup: HistoricalLexiconLookup
    private let morphologyStage: OldNorseMorphologyStage
    private let phonologyStage = YoungerFutharkPhonologyStage()
    private let renderer = YoungerFutharkRenderer()
    private let evidenceSynthesizer: TranslationEvidenceSynthesizer
    let datasetVersion: String

    init(lexiconStore: HistoricalLexiconStore, runicCorpusStore: RunicCorpusStore) {
        let catalog = HistoricalSourceCatalog(
            sourceManifest: lexiconStore.sourceManifest(),
            corpusReferences: runicCorpusStore.runicCorpusReferences()
        )
        let lookup = HistoricalLexiconLookup(lexiconStore: lexiconStore, sourceCatalog: catalog)
        sourceCatalog = catalog
        goldExampleResolver = TranslationGoldExampleResolver(runicCorpusStore: runicCorpusStore)
        phraseTemplateResolver = RunicPhraseTemplateResolver(
            runicCorpusStore: runicCorpusStore,
            sourceCatalog: catalog
        )
        lexiconLookup = lookup
        morphologyStage = OldNorseMorphologyStage(lexiconLookup: lookup)
        evidenceSynthesizer = TranslationEvidenceSynthesizer(datasetVersion: lookup.datasetVersion())
        datasetVersion = lookup.datasetVersion()
    }

    func translate(_ request: TranslationRequest) -> TranslationResult {
        if let gold = goldExampleResolver.resolve(
            request: request,
            engineVersion: engineVersion
        ) {
            return gold
        }
        if let template = phraseTemplateResolver.resolveYounger(
            request: request,
            renderer: renderer
        ) {
            return template.withEngineVersion(engineVersion)
        }

        let parsed = parser.parse(request.sourceText)
        let grammarRules = lexiconLookup.grammarRules()
        let resolutions = parsed.tokens.compactMap { token -> TranslationTokenResolution? in
            if token.type == .punctuation {
                return token.asPunctuationResolution()
            }
            if grammarRules.removableWords.contains(token.normalized) {
                return nil
            }
            return resolveToken(token, request: request)
        }

        return evidenceSynthesizer.buildResult(
            request: request,
            resolutions: resolutions,
            evidenceRequest: TranslationEvidenceRequest(
                script: script,
                derivationKind: .tokenComposed,
                historicalStage: .oldNorse,
                engineVersion: engineVersion,
                requestedVariant: request.youngerVariant.rawValue,
                baseConfidence: youngerBaseConfidence(for: request.fidelity),
                fallbackStatus: .reconstructed,
                defaultNote: "Generated using the offline Old Norse translation pipeline."
            )
        )
    }

    private func resolveToken(
        _ token: ParsedEnglishToken,
        request: TranslationRequest
    ) -> TranslationTokenResolution {
        var provenance: [TranslationProvenanceEntry] = []
        var notes: [String] = []
        var resolutionStatus: TranslationResolutionStatus = .reconstructed

        let normalized: String
        if let pronoun = lexiconLookup.grammarRules().pronounMap[token.normalized] {
            provenance.append(
                lexiconLookup.provenanceFor(
                    sourceID: "internal_heuristics",
                    detail: "Pronoun mapping"
                )
            )
            normalized = pronoun
        } else if let preposition = lexiconLookup.grammarRules().prepositionMap[token.normalized] {
            provenance.append(
                lexiconLookup.provenanceFor(
                    sourceID: "internal_heuristics",
                    detail: "Preposition mapping"
                )
            )
            normalized = preposition
        } else if let name = lexiconLookup.resolveName(token.normalized) {
            provenance.append(
                lexiconLookup.provenanceFor(
                    sourceID: "internal_heuristics",
                    detail: "Curated name adaptation"
                )
            )
            normalized = name
        } else if let entry = lexiconLookup.oldNorseFor(token.normalized, fidelity: request.fidelity) {
            provenance.append(lexiconLookup.provenanceFor(entry: entry))
            let morphology = morphologyStage.inflect(entry: entry, token: token)
            notes.append(contentsOf: morphology.notes)
            normalized = morphology.form
        } else if request.fidelity != .strict, let paraphrase = lexiconLookup.fallbackParaphrase(token.normalized) {
            resolutionStatus = .approximated
            notes.append("Used descriptive paraphrase for '\(token.raw)'.")
            provenance.append(
                lexiconLookup.provenanceFor(
                    sourceID: "internal_heuristics",
                    detail: "Readable-mode paraphrase"
                )
            )
            normalized = paraphrase
        } else if request.fidelity != .strict {
            resolutionStatus = .approximated
            notes.append(
                request.fidelity == .decorative
                    ? "Decorative mode preserved '\(token.raw)' phonetically."
                    : "Readable mode preserved '\(token.raw)' phonetically."
            )
            provenance.append(
                lexiconLookup.provenanceFor(
                    sourceID: "internal_heuristics",
                    detail: "Phonological preservation fallback"
                )
            )
            normalized = token.normalized
        } else {
            return TranslationTokenResolution(
                sourceToken: token.raw,
                normalizedToken: "",
                diplomaticToken: "",
                glyphToken: "",
                resolutionStatus: .unavailable,
                notes: ["Missing Old Norse lemma for '\(token.raw)'."],
                unresolvedToken: token.raw
            )
        }

        let phonology = phonologyStage.rewrite(normalized)
        notes.append(contentsOf: phonology.notes)
        let diplomatic = phonology.form
        let glyph = renderer.render(diplomatic, variant: request.youngerVariant)

        return TranslationTokenResolution(
            sourceToken: token.raw,
            normalizedToken: normalized,
            diplomaticToken: diplomatic,
            glyphToken: glyph,
            resolutionStatus: resolutionStatus,
            notes: Array(Set(notes)),
            provenance: provenance.uniquedBy(\.stableID)
        )
    }
}

private struct ElderFutharkTranslationEngine: TranslationEngine {
    let script: RunicScript = .elder
    let engineVersion = "ef-translation-v3"

    private let parser = EnglishSyntaxParser()
    private let goldExampleResolver: TranslationGoldExampleResolver
    private let phraseTemplateResolver: RunicPhraseTemplateResolver
    private let lexiconLookup: HistoricalLexiconLookup
    private let lexicalStage: ProtoNorseLexicalStage
    private let renderer = ElderRuneRenderer()
    private let evidenceSynthesizer: TranslationEvidenceSynthesizer
    let datasetVersion: String

    init(lexiconStore: HistoricalLexiconStore, runicCorpusStore: RunicCorpusStore) {
        let sourceCatalog = HistoricalSourceCatalog(
            sourceManifest: lexiconStore.sourceManifest(),
            corpusReferences: runicCorpusStore.runicCorpusReferences()
        )
        let lookup = HistoricalLexiconLookup(lexiconStore: lexiconStore, sourceCatalog: sourceCatalog)
        goldExampleResolver = TranslationGoldExampleResolver(runicCorpusStore: runicCorpusStore)
        phraseTemplateResolver = RunicPhraseTemplateResolver(
            runicCorpusStore: runicCorpusStore,
            sourceCatalog: sourceCatalog
        )
        lexiconLookup = lookup
        lexicalStage = ProtoNorseLexicalStage(lexiconLookup: lookup)
        evidenceSynthesizer = TranslationEvidenceSynthesizer(datasetVersion: lookup.datasetVersion())
        datasetVersion = lookup.datasetVersion()
    }

    func translate(_ request: TranslationRequest) -> TranslationResult {
        if let gold = goldExampleResolver.resolve(
            request: request,
            engineVersion: engineVersion
        ) {
            return gold
        }
        if let template = phraseTemplateResolver.resolveElder(
            request: request,
            renderer: renderer
        ) {
            return template.withEngineVersion(engineVersion)
        }

        if request.fidelity == .strict {
            return strictUnavailableResult(request)
        }

        let parsed = parser.parse(request.sourceText)
        let resolutions = parsed.tokens.map { token in
            if token.type == .punctuation {
                return token.asPunctuationResolution()
            }

            let output = lexicalStage.reconstruct(token: token, fidelity: request.fidelity)
            if let unresolved = output.unresolvedToken {
                return TranslationTokenResolution(
                    sourceToken: token.raw,
                    normalizedToken: "",
                    diplomaticToken: "",
                    glyphToken: "",
                    resolutionStatus: .unavailable,
                    notes: output.notes,
                    unresolvedToken: unresolved
                )
            }

            let normalized = output.form ?? ""
            return TranslationTokenResolution(
                sourceToken: token.raw,
                normalizedToken: normalized,
                diplomaticToken: normalized,
                glyphToken: renderer.render(normalized),
                resolutionStatus: output.resolutionStatus,
                notes: output.notes,
                provenance: output.provenance
            )
        }

        return evidenceSynthesizer.buildResult(
            request: request,
            resolutions: resolutions,
            evidenceRequest: TranslationEvidenceRequest(
                script: script,
                derivationKind: .tokenComposed,
                historicalStage: .protoNorse,
                engineVersion: engineVersion,
                baseConfidence: elderBaseConfidence(for: request.fidelity),
                fallbackStatus: .reconstructed,
                defaultNote: "Generated using the offline Proto-Norse translation pipeline."
            )
        )
    }

    private func strictUnavailableResult(_ request: TranslationRequest) -> TranslationResult {
        TranslationResult(
            sourceText: request.sourceText,
            script: request.script,
            fidelity: request.fidelity,
            derivationKind: .phraseTemplate,
            historicalStage: .protoNorse,
            normalizedForm: "",
            diplomaticForm: "",
            glyphOutput: "",
            resolutionStatus: .unavailable,
            confidence: 0,
            notes: ["Missing attested or reconstructed Elder Futhark pattern for this phrase."],
            unresolvedTokens: request.sourceText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? []
                : [request.sourceText.trimmingCharacters(in: .whitespacesAndNewlines)],
            provenance: [],
            tokenBreakdown: [],
            engineVersion: engineVersion,
            datasetVersion: datasetVersion
        )
    }
}

private struct EreborCirthTranslationEngine: TranslationEngine {
    let script: RunicScript = .cirth
    let engineVersion = "cirth-translation-v3"

    private let parser = EnglishSyntaxParser()
    private let goldExampleResolver: TranslationGoldExampleResolver
    private let tokenizer: CirthOrthographyStage
    private let evidenceSynthesizer: TranslationEvidenceSynthesizer
    let datasetVersion: String

    init(runicCorpusStore: RunicCorpusStore, ereborStore: EreborOrthographyStore) {
        let sourceCatalog = HistoricalSourceCatalog(
            sourceManifest: ereborStore.sourceManifest(),
            corpusReferences: runicCorpusStore.runicCorpusReferences()
        )
        goldExampleResolver = TranslationGoldExampleResolver(
            runicCorpusStore: runicCorpusStore,
            cirthRenderer: CirthFontRenderer(wordSeparator: ereborStore.ereborTables().wordSeparator)
        )
        tokenizer = CirthOrthographyStage(
            ereborStore: ereborStore,
            sourceCatalog: sourceCatalog
        )
        evidenceSynthesizer = TranslationEvidenceSynthesizer(datasetVersion: ereborStore.datasetManifest().version)
        datasetVersion = ereborStore.datasetManifest().version
    }

    func translate(_ request: TranslationRequest) -> TranslationResult {
        if let gold = goldExampleResolver.resolve(
            request: request,
            engineVersion: engineVersion
        ) {
            return gold
        }
        if let phrase = tokenizer.resolvePhrase(request: request) {
            return phrase.with(
                engineVersion: engineVersion,
                datasetVersion: datasetVersion
            )
        }

        let parsed = parser.parse(request.sourceText)
        let resolutions = parsed.tokens.map { token in
            if token.type == .punctuation {
                return token.asPunctuationResolution()
            }

            let output = tokenizer.renderToken(token: token.normalized, fidelity: request.fidelity)
            if let unresolved = output.unresolvedToken {
                return TranslationTokenResolution(
                    sourceToken: token.raw,
                    normalizedToken: "",
                    diplomaticToken: "",
                    glyphToken: "",
                    resolutionStatus: .unavailable,
                    notes: output.notes,
                    unresolvedToken: unresolved
                )
            }

            return TranslationTokenResolution(
                sourceToken: token.raw,
                normalizedToken: token.normalized,
                diplomaticToken: output.diplomatic ?? "",
                glyphToken: output.glyphs ?? "",
                resolutionStatus: output.resolutionStatus,
                notes: output.notes,
                provenance: output.provenance
            )
        }

        return evidenceSynthesizer.buildResult(
            request: request,
            resolutions: resolutions,
            evidenceRequest: TranslationEvidenceRequest(
                script: script,
                derivationKind: .sequenceTranscription,
                historicalStage: .ereborEnglish,
                engineVersion: engineVersion,
                baseConfidence: cirthBaseConfidence(for: request.fidelity),
                fallbackStatus: .reconstructed,
                defaultNote: "Generated using the offline Erebor transcription pipeline."
            )
        )
    }
}

// MARK: - Parsing

private struct EnglishSyntaxParser {
    func parse(_ text: String) -> ParsedEnglishText {
        let normalized = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)

        let tokens = tokenRegex
            .matches(in: normalized, range: NSRange(normalized.startIndex..., in: normalized))
            .compactMap { Range($0.range, in: normalized).map { normalized[$0] } }
            .map(String.init)
            .map { value in
                ParsedEnglishToken(
                    raw: value,
                    normalized: value.lowercased(),
                    type: value.allSatisfy { $0.isLetter || $0 == "'" } ? .word : .punctuation
                )
            }

        let firstVerbIndex = tokens.firstIndex {
            $0.type == .word && ($0.normalized.hasSuffix("s") || $0.normalized.hasSuffix("ed"))
        } ?? tokens.count
        let firstPrepositionIndex = tokens.firstIndex {
            commonPrepositions.contains($0.normalized)
        }

        return ParsedEnglishText(
            originalText: text,
            normalizedText: normalized,
            tokens: tokens,
            subjectTokens: tokens.safeSlice(from: 0, to: firstVerbIndex),
            verbTokens: firstVerbIndex < tokens.count ? [tokens[firstVerbIndex]] : [],
            modifierTokens: firstPrepositionIndex.map { Array(tokens.dropFirst($0)) } ?? []
        )
    }

    private let tokenRegex = (try? NSRegularExpression(pattern: #"[A-Za-z']+|[.,!?;:-]"#))
        ?? NSRegularExpression()
    private let commonPrepositions = Set(["at", "in", "on", "under", "with", "for", "from", "to", "of"])
}

private struct ParsedEnglishText: Sendable {
    let originalText: String
    let normalizedText: String
    let tokens: [ParsedEnglishToken]
    let subjectTokens: [ParsedEnglishToken]
    let verbTokens: [ParsedEnglishToken]
    let modifierTokens: [ParsedEnglishToken]
}

private struct ParsedEnglishToken: Sendable {
    let raw: String
    let normalized: String
    let type: ParsedEnglishTokenType
}

private enum ParsedEnglishTokenType: Sendable {
    case word
    case punctuation
}

// MARK: - Shared Helpers

private struct TranslationGoldExampleResolver {
    let runicCorpusStore: RunicCorpusStore
    let cirthRenderer: CirthFontRenderer?

    init(runicCorpusStore: RunicCorpusStore, cirthRenderer: CirthFontRenderer? = nil) {
        self.runicCorpusStore = runicCorpusStore
        self.cirthRenderer = cirthRenderer
    }

    func resolve(request: TranslationRequest, engineVersion: String) -> TranslationResult? {
        guard let example = runicCorpusStore.goldExamples().first(where: {
            $0.sourceText.normalizePhraseKey() == request.sourceText.normalizePhraseKey()
        }) else {
            return nil
        }

        guard let result = example.results.first(where: {
            $0.script == request.script.translationScriptName &&
                $0.fidelity == request.fidelity.rawValue &&
                (request.script != .younger || $0.requestedVariant == nil || $0.requestedVariant == request.youngerVariant.rawValue)
        }) else {
            return nil
        }

        let tokenBreakdown = result.tokenBreakdown.map { token in
            let glyphToken: String
            if request.script == .cirth, let cirthRenderer {
                glyphToken = cirthRenderer.render(diplomatic: token.diplomaticToken)
            } else if request.script == .younger, request.youngerVariant == .shortTwig {
                glyphToken = YoungerFutharkRenderer().render(token.diplomaticToken, variant: .shortTwig)
            } else {
                glyphToken = token.glyphToken
            }

            return TranslationTokenBreakdown(
                sourceToken: token.sourceToken,
                normalizedToken: token.normalizedToken,
                diplomaticToken: token.diplomaticToken,
                glyphToken: glyphToken,
                resolutionStatus: token.resolutionStatus,
                provenance: token.provenance
            )
        }

        let glyphOutput: String
        if request.script == .cirth, let cirthRenderer {
            glyphOutput = cirthRenderer.render(diplomatic: result.diplomaticForm)
        } else if request.script == .younger, request.youngerVariant == .shortTwig {
            glyphOutput = YoungerFutharkRenderer().render(result.diplomaticForm, variant: .shortTwig)
        } else {
            glyphOutput = result.glyphOutput
        }

        return TranslationResult(
            sourceText: request.sourceText,
            script: request.script,
            fidelity: request.fidelity,
            derivationKind: TranslationDerivationKind(rawValue: result.derivationKind) ?? .goldExample,
            historicalStage: HistoricalStage(rawValue: result.historicalStage) ?? .modernEnglish,
            normalizedForm: result.normalizedForm,
            diplomaticForm: result.diplomaticForm,
            glyphOutput: glyphOutput,
            requestedVariant: request.script == .younger ? request.youngerVariant.rawValue : result.requestedVariant,
            resolutionStatus: TranslationResolutionStatus(rawValue: result.resolutionStatus) ?? .unavailable,
            confidence: result.confidence,
            notes: result.notes,
            unresolvedTokens: result.unresolvedTokens,
            provenance: result.provenance,
            tokenBreakdown: tokenBreakdown,
            engineVersion: engineVersion,
            datasetVersion: runicCorpusStore.datasetManifest().version
        )
    }
}

private struct HistoricalSourceCatalog {
    private let sourceEntries: [String: TranslationSourceEntry]
    private let corpusReferences: [String: RunicCorpusReferenceEntry]

    init(sourceManifest: TranslationSourceManifest, corpusReferences: [RunicCorpusReferenceEntry] = []) {
        sourceEntries = Dictionary(uniqueKeysWithValues: sourceManifest.sources.map { ($0.id, $0) })
        self.corpusReferences = Dictionary(uniqueKeysWithValues: corpusReferences.map { ($0.id, $0) })
    }

    func provenanceFor(
        sourceID: String,
        referenceID: String? = nil,
        detail: String? = nil
    ) -> TranslationProvenanceEntry {
        let source = sourceEntries[sourceID]
            ?? sourceEntries["internal_heuristics"]
            ?? TranslationSourceEntry(
                id: "internal_heuristics",
                name: "Runatal heuristics",
                role: "Offline fallback logic and generated educational notes",
                license: "Project-owned",
                url: "https://github.com/po4yka/runatal-ios"
            )
        let reference = referenceID.flatMap { corpusReferences[$0] }
        return TranslationProvenanceEntry(
            sourceID: source.id,
            referenceID: referenceID,
            label: reference?.label ?? source.name,
            role: source.role,
            license: source.license,
            detail: detail ?? reference?.detail,
            url: reference?.url ?? source.url
        )
    }
}

private struct HistoricalLexiconLookup {
    private let lexiconStore: HistoricalLexiconStore
    private let sourceCatalog: HistoricalSourceCatalog
    private let oldNorseEntries: [String: OldNorseLexiconEntry]
    private let protoNorseEntries: [String: ProtoNorseLexiconEntry]

    init(lexiconStore: HistoricalLexiconStore, sourceCatalog: HistoricalSourceCatalog) {
        self.lexiconStore = lexiconStore
        self.sourceCatalog = sourceCatalog
        oldNorseEntries = Dictionary(
            uniqueKeysWithValues: lexiconStore.oldNorseLexicon().map { ($0.english.lowercased(), $0) }
        )
        protoNorseEntries = Dictionary(
            uniqueKeysWithValues: lexiconStore.protoNorseLexicon().map { ($0.english.lowercased(), $0) }
        )
    }

    func datasetVersion() -> String { lexiconStore.datasetManifest().version }

    func oldNorseFor(_ token: String, fidelity: TranslationFidelity) -> OldNorseLexiconEntry? {
        let normalized = resolveSynonym(token)
        guard let entry = oldNorseEntries[normalized] else { return nil }
        return fidelity == .strict && !entry.strictEligible ? nil : entry
    }

    func protoNorseFor(_ token: String, fidelity: TranslationFidelity) -> ProtoNorseLexiconEntry? {
        let normalized = resolveSynonym(token)
        guard let entry = protoNorseEntries[normalized] else { return nil }
        return fidelity == .strict && !entry.strictEligible ? nil : entry
    }

    func resolveName(_ token: String) -> String? {
        lexiconStore.nameAdaptations().names[token]
    }

    func fallbackParaphrase(_ token: String) -> String? {
        lexiconStore.fallbackTemplates().paraphrases[token]
    }

    func grammarRules() -> GrammarRulesData {
        lexiconStore.grammarRules()
    }

    func paradigmTables() -> ParadigmTablesData {
        lexiconStore.paradigmTables()
    }

    func provenanceFor(entry: OldNorseLexiconEntry) -> TranslationProvenanceEntry {
        sourceCatalog.provenanceFor(
            sourceID: entry.sourceID,
            referenceID: entry.id,
            detail: entry.citations.joined(separator: ", ").nilIfEmpty
        )
    }

    func provenanceFor(entry: ProtoNorseLexiconEntry) -> TranslationProvenanceEntry {
        sourceCatalog.provenanceFor(
            sourceID: entry.sourceID,
            referenceID: entry.id,
            detail: entry.citations.joined(separator: ", ").nilIfEmpty
        )
    }

    func provenanceFor(sourceID: String, referenceID: String? = nil, detail: String? = nil) -> TranslationProvenanceEntry {
        sourceCatalog.provenanceFor(sourceID: sourceID, referenceID: referenceID, detail: detail)
    }

    private func resolveSynonym(_ token: String) -> String {
        lexiconStore.fallbackTemplates().synonyms[token] ?? token
    }
}

private struct RunicPhraseTemplateResolver {
    let runicCorpusStore: RunicCorpusStore
    let sourceCatalog: HistoricalSourceCatalog

    func resolveYounger(
        request: TranslationRequest,
        renderer: YoungerFutharkRenderer
    ) -> TranslationResult? {
        guard let template = findTemplate(request: request, templates: runicCorpusStore.youngerPhraseTemplates()) else {
            return nil
        }
        return toTranslationResult(
            template: template,
            request: request,
            script: .younger,
            datasetVersion: runicCorpusStore.datasetManifest().version,
            engineVersion: "yf-template-v3"
        ) { renderer.render($0, variant: request.youngerVariant) }
    }

    func resolveElder(
        request: TranslationRequest,
        renderer: ElderRuneRenderer
    ) -> TranslationResult? {
        guard let template = findTemplate(request: request, templates: runicCorpusStore.elderAttestedForms()) else {
            return nil
        }
        return toTranslationResult(
            template: template,
            request: request,
            script: .elder,
            datasetVersion: runicCorpusStore.datasetManifest().version,
            engineVersion: "ef-template-v3"
        ) { renderer.render($0) }
    }

    private func findTemplate(
        request: TranslationRequest,
        templates: [HistoricalPhraseTemplateEntry]
    ) -> HistoricalPhraseTemplateEntry? {
        let candidates = templates.filter {
            $0.script == request.script.translationScriptName &&
                $0.sourceText.normalizePhraseKey() == request.sourceText.normalizePhraseKey()
        }
        return candidates.first(where: { $0.fidelity == request.fidelity.rawValue }) ??
            candidates.first(where: { $0.fidelity == TranslationFidelity.strict.rawValue })
    }

    private func toTranslationResult(
        template: HistoricalPhraseTemplateEntry,
        request: TranslationRequest,
        script: RunicScript,
        datasetVersion: String,
        engineVersion: String,
        glyphRenderer: (String) -> String
    ) -> TranslationResult {
        let referencesByID = Dictionary(
            uniqueKeysWithValues: runicCorpusStore.runicCorpusReferences().map { ($0.id, $0) }
        )
        let provenance = template.referenceIDs.map { referenceID in
            let sourceID = referencesByID[referenceID]?.sourceID ?? "internal_heuristics"
            return sourceCatalog.provenanceFor(sourceID: sourceID, referenceID: referenceID)
        }
        let breakdown = template.tokenBreakdown.map { token in
            let tokenProvenance = token.referenceIDs.map { referenceID in
                let sourceID = referencesByID[referenceID]?.sourceID ?? "internal_heuristics"
                return sourceCatalog.provenanceFor(sourceID: sourceID, referenceID: referenceID)
            }
            return TranslationTokenBreakdown(
                sourceToken: token.sourceToken,
                normalizedToken: token.normalizedToken,
                diplomaticToken: token.diplomaticToken,
                glyphToken: glyphRenderer(token.diplomaticToken),
                resolutionStatus: TranslationResolutionStatus(rawValue: token.resolutionStatus) ?? .unavailable,
                provenance: tokenProvenance
            )
        }
        let diplomaticTokens = breakdown.map(\.diplomaticToken)
        return TranslationResult(
            sourceText: request.sourceText,
            script: script,
            fidelity: request.fidelity,
            derivationKind: TranslationDerivationKind(rawValue: template.derivationKind) ?? .phraseTemplate,
            historicalStage: HistoricalStage(rawValue: template.historicalStage) ?? .modernEnglish,
            normalizedForm: template.normalizedForm,
            diplomaticForm: template.diplomaticForm,
            glyphOutput: stitchTokens(diplomaticTokens.map(glyphRenderer)),
            requestedVariant: script == .younger ? request.youngerVariant.rawValue : nil,
            resolutionStatus: TranslationResolutionStatus(rawValue: template.resolutionStatus) ?? .unavailable,
            confidence: confidenceFor(
                status: TranslationResolutionStatus(rawValue: template.resolutionStatus) ?? .unavailable
            ),
            notes: template.notes,
            unresolvedTokens: [],
            provenance: provenance,
            tokenBreakdown: breakdown,
            engineVersion: engineVersion,
            datasetVersion: datasetVersion
        )
    }
}

private struct TranslationTokenResolution: Sendable {
    let sourceToken: String
    let normalizedToken: String
    let diplomaticToken: String
    let glyphToken: String
    let resolutionStatus: TranslationResolutionStatus
    let notes: [String]
    let unresolvedToken: String?
    let provenance: [TranslationProvenanceEntry]

    init(
        sourceToken: String,
        normalizedToken: String,
        diplomaticToken: String,
        glyphToken: String,
        resolutionStatus: TranslationResolutionStatus,
        notes: [String] = [],
        unresolvedToken: String? = nil,
        provenance: [TranslationProvenanceEntry] = []
    ) {
        self.sourceToken = sourceToken
        self.normalizedToken = normalizedToken
        self.diplomaticToken = diplomaticToken
        self.glyphToken = glyphToken
        self.resolutionStatus = resolutionStatus
        self.notes = notes
        self.unresolvedToken = unresolvedToken
        self.provenance = provenance
    }
}

private struct MorphologyHints: Sendable {
    let isPlural: Bool
    let isPast: Bool
    let isThirdPersonSingular: Bool
}

private struct MorphologyStageOutput: Sendable {
    let form: String
    let notes: [String]
}

private struct OldNorseMorphologyStage {
    let lexiconLookup: HistoricalLexiconLookup

    func inflect(entry: OldNorseLexiconEntry, token: ParsedEnglishToken) -> MorphologyStageOutput {
        let hints = token.toMorphologyHints()
        switch entry.partOfSpeech {
        case "verb":
            return MorphologyStageOutput(
                form: inflectVerb(entry: entry, hints: hints),
                notes: entry.paradigmID.map { ["Applied verb paradigm \($0)."] } ?? []
            )
        case "noun":
            return MorphologyStageOutput(
                form: inflectNoun(entry: entry, hints: hints),
                notes: entry.paradigmID.map { ["Applied noun paradigm \($0)."] } ?? []
            )
        case "preposition":
            return MorphologyStageOutput(form: entry.dativePhrase ?? entry.lemma, notes: [])
        default:
            return MorphologyStageOutput(form: entry.lemma, notes: [])
        }
    }

    private func inflectVerb(entry: OldNorseLexiconEntry, hints: MorphologyHints) -> String {
        let paradigm = entry.paradigmID.flatMap { lexiconLookup.paradigmTables().verbParadigms[$0] }
        let pastForm: String? = if hints.isPast {
            entry.past3sg ?? paradigm.map { entry.lemma.replacingOccurrences(of: "a$", with: "", options: .regularExpression) + $0.thirdPersonPastSuffix }
        } else {
            nil
        }
        let presentForm: String? = if hints.isThirdPersonSingular {
            entry.present3sg ?? paradigm.map { entry.lemma.replacingOccurrences(of: "a$", with: "", options: .regularExpression) + $0.thirdPersonPresentSuffix }
        } else {
            nil
        }
        return pastForm ?? presentForm ?? entry.lemma
    }

    private func inflectNoun(entry: OldNorseLexiconEntry, hints: MorphologyHints) -> String {
        let paradigm = entry.paradigmID.flatMap { lexiconLookup.paradigmTables().nounParadigms[$0] }
        let inflected: String? = if hints.isPlural {
            if let plural = entry.pluralForm {
                plural
            } else if let paradigm, !paradigm.pluralSuffix.isEmpty {
                entry.lemma.hasSuffix("r")
                    ? String(entry.lemma.dropLast()) + paradigm.pluralSuffix
                    : entry.lemma + paradigm.pluralSuffix
            } else {
                nil
            }
        } else {
            nil
        }
        return inflected ?? entry.lemma
    }
}

private struct PhonologyStageOutput: Sendable {
    let form: String
    let notes: [String]
}

private struct YoungerFutharkPhonologyStage {
    func rewrite(_ text: String) -> PhonologyStageOutput {
        var current = text.lowercased()
        var notes: [String] = []

        current = applyRegexRule(
            value: current,
            pattern: #"[eéæ]"#,
            replacement: "i",
            notes: &notes,
            note: "Applied front-vowel reduction group."
        )
        current = applyLiteralRule(
            value: current,
            target: "ja",
            replacement: "ia",
            notes: &notes,
            note: "Normalized glide-plus-vowel spelling for Younger Futhark."
        )
        current = applyRegexRule(
            value: current,
            pattern: #"[oóǫøy]"#,
            replacement: "u",
            notes: &notes,
            note: "Applied rounded-vowel reduction group."
        )
        current = applyLiteralRule(
            value: current,
            target: "ei",
            replacement: "i",
            notes: &notes,
            note: "Applied diphthong handling group."
        )
        current = applyLiteralRule(
            value: current,
            target: "ey",
            replacement: "y",
            notes: &notes,
            note: "Applied diphthong handling group."
        )
        current = applyLiteralRule(
            value: current,
            target: "g",
            replacement: "k",
            notes: &notes,
            note: "Applied voicing-neutralization group."
        )
        current = applyLiteralRule(
            value: current,
            target: "d",
            replacement: "t",
            notes: &notes,
            note: "Applied devoicing group."
        )
        current = applyLiteralRule(
            value: current,
            target: "ð",
            replacement: "þ",
            notes: &notes,
            note: "Normalized eth to thorn."
        )
        for (target, replacement) in [("ll", "l"), ("nn", "n"), ("mm", "m"), ("rr", "r")] {
            current = applyLiteralRule(
                value: current,
                target: target,
                replacement: replacement,
                notes: &notes,
                note: "Applied geminate-simplification group."
            )
        }

        return PhonologyStageOutput(form: current, notes: Array(Set(notes)))
    }

    private func applyRegexRule(
        value: String,
        pattern: String,
        replacement: String,
        notes: inout [String],
        note: String
    ) -> String {
        let replaced = value.replacingOccurrences(of: pattern, with: replacement, options: .regularExpression)
        if replaced != value {
            notes.append(note)
        }
        return replaced
    }

    private func applyLiteralRule(
        value: String,
        target: String,
        replacement: String,
        notes: inout [String],
        note: String
    ) -> String {
        let replaced = value.replacingOccurrences(of: target, with: replacement)
        if replaced != value {
            notes.append(note)
        }
        return replaced
    }
}

private struct YoungerFutharkRenderer {
    private let longBranchMap: [Character: Character] = [
        "f": "ᚠ", "u": "ᚢ", "v": "ᚢ", "w": "ᚢ", "þ": "ᚦ",
        "a": "ᛅ", "ą": "ᚬ", "r": "ᚱ", "ʀ": "ᛦ", "k": "ᚴ",
        "g": "ᚴ", "h": "ᚼ", "n": "ᚾ", "i": "ᛁ", "j": "ᛁ",
        "s": "ᛋ", "t": "ᛏ", "d": "ᛏ", "b": "ᛒ", "p": "ᛒ",
        "m": "ᛘ", "l": "ᛚ", " ": " "
    ]

    private let shortTwigMap: [Character: Character] = [
        "f": "ᚠ", "u": "ᚢ", "v": "ᚢ", "w": "ᚢ", "þ": "ᚦ",
        "a": "ᛆ", "ą": "ᚭ", "r": "ᚱ", "ʀ": "ᛧ", "k": "ᚴ",
        "g": "ᚴ", "h": "ᚽ", "n": "ᚿ", "i": "ᛁ", "j": "ᛁ",
        "s": "ᛌ", "t": "ᛐ", "d": "ᛐ", "b": "ᛓ", "p": "ᛓ",
        "m": "ᛙ", "l": "ᛚ", " ": " "
    ]

    func render(_ text: String, variant: YoungerFutharkVariant) -> String {
        let map = variant == .longBranch ? longBranchMap : shortTwigMap
        return String(text.map { map[$0] ?? $0 })
    }
}

private struct ProtoNorseStageOutput: Sendable {
    let form: String?
    let notes: [String]
    let resolutionStatus: TranslationResolutionStatus
    let unresolvedToken: String?
    let provenance: [TranslationProvenanceEntry]
}

private struct ProtoNorseLexicalStage {
    let lexiconLookup: HistoricalLexiconLookup

    func reconstruct(token: ParsedEnglishToken, fidelity: TranslationFidelity) -> ProtoNorseStageOutput {
        let entry = lexiconLookup.protoNorseFor(token.normalized, fidelity: fidelity)
        let paraphrase = lexiconLookup.fallbackParaphrase(token.normalized)

        if let entry {
            return ProtoNorseStageOutput(
                form: entry.form,
                notes: [],
                resolutionStatus: entry.strictEligible ? .reconstructed : .approximated,
                unresolvedToken: nil,
                provenance: [lexiconLookup.provenanceFor(entry: entry)]
            )
        }

        if fidelity == .strict {
            return ProtoNorseStageOutput(
                form: nil,
                notes: ["Missing attested or reconstructed Elder Futhark pattern for '\(token.raw)'."],
                resolutionStatus: .unavailable,
                unresolvedToken: token.raw,
                provenance: []
            )
        }

        if let paraphrase {
            return ProtoNorseStageOutput(
                form: paraphrase.lowercased(),
                notes: ["Used descriptive paraphrase for '\(token.raw)'."],
                resolutionStatus: .approximated,
                unresolvedToken: nil,
                provenance: [
                    lexiconLookup.provenanceFor(
                        sourceID: "internal_heuristics",
                        detail: "Readable-mode paraphrase"
                    )
                ]
            )
        }

        return ProtoNorseStageOutput(
            form: token.normalized,
            notes: ["Used phonological preservation for '\(token.raw)'."],
            resolutionStatus: .approximated,
            unresolvedToken: nil,
            provenance: [
                lexiconLookup.provenanceFor(
                    sourceID: "internal_heuristics",
                    detail: "Proto-Norse preservation fallback"
                )
            ]
        )
    }
}

private struct CirthOrthographyOutput: Sendable {
    let diplomatic: String?
    let glyphs: String?
    let notes: [String]
    let resolutionStatus: TranslationResolutionStatus
    let unresolvedToken: String?
    let provenance: [TranslationProvenanceEntry]
}

private struct CirthOrthographyStage {
    let ereborStore: EreborOrthographyStore
    let sourceCatalog: HistoricalSourceCatalog
    let renderer: CirthFontRenderer

    init(ereborStore: EreborOrthographyStore, sourceCatalog: HistoricalSourceCatalog) {
        self.ereborStore = ereborStore
        self.sourceCatalog = sourceCatalog
        renderer = CirthFontRenderer(wordSeparator: ereborStore.ereborTables().wordSeparator)
    }

    func resolvePhrase(request: TranslationRequest) -> TranslationResult? {
        guard let mapping = ereborStore.ereborTables().phraseMappings.first(where: {
            $0.sourceText.normalizePhraseKey() == request.sourceText.normalizePhraseKey()
        }) else {
            return nil
        }

        return TranslationResult(
            sourceText: request.sourceText,
            script: .cirth,
            fidelity: request.fidelity,
            derivationKind: .phraseTemplate,
            historicalStage: .ereborEnglish,
            normalizedForm: request.sourceText.lowercased(),
            diplomaticForm: mapping.diplomaticForm,
            glyphOutput: renderer.render(diplomatic: mapping.diplomaticForm),
            resolutionStatus: TranslationResolutionStatus(rawValue: mapping.resolutionStatus) ?? .unavailable,
            confidence: confidenceFor(status: TranslationResolutionStatus(rawValue: mapping.resolutionStatus) ?? .unavailable),
            notes: mapping.notes,
            unresolvedTokens: [],
            provenance: mapping.referenceIDs.map {
                sourceCatalog.provenanceFor(
                    sourceID: "tolkien_appendix_e",
                    referenceID: $0
                )
            },
            tokenBreakdown: [],
            engineVersion: "cirth-phrase-v3",
            datasetVersion: ereborStore.datasetManifest().version
        )
    }

    func renderToken(token: String, fidelity: TranslationFidelity) -> CirthOrthographyOutput {
        let tables = ereborStore.ereborTables()
        let sequenceMappings = tables.longConsonants.merging(tables.longVowels) { current, _ in current }
            .merging(tables.sequences) { current, _ in current }
        let allSequences = sequenceMappings.keys.sorted { $0.count > $1.count }
        var diplomaticTokens: [String] = []
        var remaining = token.lowercased()
        var appliedCanonicalRule = false
        var approximated = false

        while !remaining.isEmpty {
            let sequence = allSequences.first { remaining.hasPrefix($0) }
            guard let firstCharacter = remaining.first else {
                break
            }
            let singleCharacter = String(firstCharacter)

            if let sequence {
                appliedCanonicalRule = true
                diplomaticTokens.append(sequence)
                remaining.removeFirst(sequence.count)
                continue
            }

            if tables.singleCharacters[singleCharacter] != nil {
                diplomaticTokens.append(singleCharacter)
                remaining.removeFirst()
                continue
            }

            if fidelity == .strict {
                return CirthOrthographyOutput(
                    diplomatic: nil,
                    glyphs: nil,
                    notes: ["Unsupported Erebor sequence in '\(token)'."],
                    resolutionStatus: .unavailable,
                    unresolvedToken: token,
                    provenance: []
                )
            }

            diplomaticTokens.append(singleCharacter)
            remaining.removeFirst()
            approximated = true
        }

        let diplomatic = diplomaticTokens.joined(separator: tables.wordSeparator)
        return CirthOrthographyOutput(
            diplomatic: diplomatic,
            glyphs: renderer.render(diplomatic: diplomatic),
            notes: [
                appliedCanonicalRule ? "Applied Erebor sequence-table transcription." : nil,
                approximated ? "Used readable-mode character fallback for an unsupported Erebor sequence." : nil
            ].compactMap { $0 },
            resolutionStatus: approximated ? .approximated : .reconstructed,
            unresolvedToken: nil,
            provenance: [
                sourceCatalog.provenanceFor(
                    sourceID: "tolkien_appendix_e",
                    detail: "Erebor orthography table"
                )
            ]
        )
    }
}

private struct CirthFontRenderer {
    let wordSeparator: String

    func render(diplomatic: String) -> String {
        let normalized = diplomatic.replacingOccurrences(of: wordSeparator, with: "")
        return RunicTransliterator.transliterate(normalized, to: .cirth)
    }
}

private struct ElderRuneRenderer {
    func render(_ text: String) -> String {
        RunicTransliterator.transliterate(text, to: .elder)
    }
}

private struct TranslationEvidenceRequest: Sendable {
    let script: RunicScript
    let derivationKind: TranslationDerivationKind
    let historicalStage: HistoricalStage
    let engineVersion: String
    let requestedVariant: String?
    let baseConfidence: Double
    let fallbackStatus: TranslationResolutionStatus
    let defaultNote: String

    init(
        script: RunicScript,
        derivationKind: TranslationDerivationKind,
        historicalStage: HistoricalStage,
        engineVersion: String,
        requestedVariant: String? = nil,
        baseConfidence: Double,
        fallbackStatus: TranslationResolutionStatus,
        defaultNote: String
    ) {
        self.script = script
        self.derivationKind = derivationKind
        self.historicalStage = historicalStage
        self.engineVersion = engineVersion
        self.requestedVariant = requestedVariant
        self.baseConfidence = baseConfidence
        self.fallbackStatus = fallbackStatus
        self.defaultNote = defaultNote
    }
}

private struct TranslationEvidenceSynthesizer {
    let datasetVersion: String

    func buildResult(
        request: TranslationRequest,
        resolutions: [TranslationTokenResolution],
        evidenceRequest: TranslationEvidenceRequest
    ) -> TranslationResult {
        let unresolvedTokens = Array(Set(resolutions.compactMap(\.unresolvedToken)))
        let provenance = resolutions.flatMap(\.provenance).uniquedBy(\.stableID)
        let notes = Array(Set(resolutions.flatMap(\.notes)))

        let resolutionStatus: TranslationResolutionStatus
        if !unresolvedTokens.isEmpty {
            resolutionStatus = .unavailable
        } else if resolutions.contains(where: { $0.resolutionStatus == .approximated }) {
            resolutionStatus = .approximated
        } else {
            resolutionStatus = evidenceRequest.fallbackStatus
        }

        let available = resolutions.filter { $0.unresolvedToken == nil }
        let normalizedForm = resolutionStatus == .unavailable ? "" : stitchTokens(available.map(\.normalizedToken))
        let diplomaticForm = resolutionStatus == .unavailable ? "" : stitchTokens(available.map(\.diplomaticToken))
        let glyphOutput = resolutionStatus == .unavailable ? "" : stitchTokens(available.map(\.glyphToken))

        return TranslationResult(
            sourceText: request.sourceText,
            script: evidenceRequest.script,
            fidelity: request.fidelity,
            derivationKind: evidenceRequest.derivationKind,
            historicalStage: evidenceRequest.historicalStage,
            normalizedForm: normalizedForm,
            diplomaticForm: diplomaticForm,
            glyphOutput: glyphOutput,
            requestedVariant: evidenceRequest.requestedVariant,
            resolutionStatus: resolutionStatus,
            confidence: confidenceFor(status: resolutionStatus, baseConfidence: evidenceRequest.baseConfidence),
            notes: notes.isEmpty ? [evidenceRequest.defaultNote] : notes,
            unresolvedTokens: unresolvedTokens,
            provenance: provenance,
            tokenBreakdown: available.map {
                TranslationTokenBreakdown(
                    sourceToken: $0.sourceToken,
                    normalizedToken: $0.normalizedToken,
                    diplomaticToken: $0.diplomaticToken,
                    glyphToken: $0.glyphToken,
                    resolutionStatus: $0.resolutionStatus,
                    provenance: $0.provenance
                )
            },
            engineVersion: evidenceRequest.engineVersion,
            datasetVersion: datasetVersion
        )
    }
}

// MARK: - Utilities

private extension ParsedEnglishToken {
    func asPunctuationResolution() -> TranslationTokenResolution {
        TranslationTokenResolution(
            sourceToken: raw,
            normalizedToken: raw,
            diplomaticToken: raw,
            glyphToken: raw,
            resolutionStatus: .reconstructed
        )
    }

    func toMorphologyHints() -> MorphologyHints {
        MorphologyHints(
            isPlural: normalized.hasSuffix("s") && !normalized.hasSuffix("'s"),
            isPast: normalized.hasSuffix("ed"),
            isThirdPersonSingular: normalized.hasSuffix("s") && !normalized.hasSuffix("ss")
        )
    }
}

private extension Array {
    func safeSlice(from startIndex: Int, to endExclusive: Int) -> [Element] {
        guard !isEmpty, startIndex < count, startIndex < endExclusive else { return [] }
        return Array(self[Swift.max(0, startIndex)..<Swift.min(count, endExclusive)])
    }
}

private extension String {
    func normalizePhraseKey() -> String {
        lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
    }

    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}

private extension TranslationProvenanceEntry {
    var stableID: String {
        [sourceID, referenceID ?? "", role, detail ?? "", label].joined(separator: "|")
    }
}

private extension TranslationResult {
    func withEngineVersion(_ engineVersion: String) -> TranslationResult {
        TranslationResult(
            sourceText: sourceText,
            script: script,
            fidelity: fidelity,
            derivationKind: derivationKind,
            historicalStage: historicalStage,
            normalizedForm: normalizedForm,
            diplomaticForm: diplomaticForm,
            glyphOutput: glyphOutput,
            requestedVariant: requestedVariant,
            resolutionStatus: resolutionStatus,
            confidence: confidence,
            notes: notes,
            unresolvedTokens: unresolvedTokens,
            provenance: provenance,
            tokenBreakdown: tokenBreakdown,
            engineVersion: engineVersion,
            datasetVersion: datasetVersion,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    func with(engineVersion: String, datasetVersion: String) -> TranslationResult {
        TranslationResult(
            sourceText: sourceText,
            script: script,
            fidelity: fidelity,
            derivationKind: derivationKind,
            historicalStage: historicalStage,
            normalizedForm: normalizedForm,
            diplomaticForm: diplomaticForm,
            glyphOutput: glyphOutput,
            requestedVariant: requestedVariant,
            resolutionStatus: resolutionStatus,
            confidence: confidence,
            notes: notes,
            unresolvedTokens: unresolvedTokens,
            provenance: provenance,
            tokenBreakdown: tokenBreakdown,
            engineVersion: engineVersion,
            datasetVersion: datasetVersion,
            createdAt: createdAt,
            updatedAt: Date()
        )
    }
}

private extension Array where Element == TranslationProvenanceEntry {
    func uniquedBy<T: Hashable>(_ keyPath: KeyPath<Element, T>) -> [Element] {
        var seen = Set<T>()
        return filter { seen.insert($0[keyPath: keyPath]).inserted }
    }
}

private func confidenceFor(
    status: TranslationResolutionStatus,
    baseConfidence: Double = 0.9
) -> Double {
    switch status {
    case .attested:
        return 0.98
    case .reconstructed:
        return baseConfidence
    case .approximated:
        return max(baseConfidence - 0.18, 0.3)
    case .unavailable:
        return 0
    }
}

private func youngerBaseConfidence(for fidelity: TranslationFidelity) -> Double {
    switch fidelity {
    case .strict:
        return 0.9
    case .readable:
        return 0.82
    case .decorative:
        return 0.7
    }
}

private func elderBaseConfidence(for fidelity: TranslationFidelity) -> Double {
    switch fidelity {
    case .strict:
        return 0.84
    case .readable:
        return 0.74
    case .decorative:
        return 0.6
    }
}

private func cirthBaseConfidence(for fidelity: TranslationFidelity) -> Double {
    switch fidelity {
    case .strict:
        return 0.72
    case .readable:
        return 0.6
    case .decorative:
        return 0.54
    }
}

private func stitchTokens(_ tokens: [String]) -> String {
    let punctuation = Set([".", ",", "!", "?", ";", ":"])
    var result = ""
    for (index, token) in tokens.enumerated() {
        if index > 0, !punctuation.contains(token), let previous = result.last, previous != " ", previous != "\n", previous != "-", previous != "·" {
            result.append(" ")
        }
        result.append(token)
    }
    return result.trimmingCharacters(in: .whitespacesAndNewlines)
}
// swiftlint:enable file_length function_body_length function_parameter_count
