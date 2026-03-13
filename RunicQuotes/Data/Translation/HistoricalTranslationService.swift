//
//  HistoricalTranslationService.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
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

private enum TranslationSourceLanguageDetector {
    static func detect(text: String, requested: TranslationSourceLanguage) -> TranslationSourceLanguage {
        guard requested == .english else { return requested }

        let letterScalars = text.unicodeScalars.filter(\.properties.isAlphabetic)
        guard !letterScalars.isEmpty else { return .english }

        let isPlainLatin = letterScalars.allSatisfy { $0.isASCII && CharacterSet.letters.contains($0) }
        return isPlainLatin ? .english : .unsupported
    }
}

/// Structured offline historical translation and Erebor transcription service.
final class HistoricalTranslationService: @unchecked Sendable {
    private let assetProvider: AssetTranslationDatasetProvider?
    private let engineFactory: TranslationEngineFactory

    init(
        lexiconStore: HistoricalLexiconStore,
        runicCorpusStore: RunicCorpusStore,
        ereborStore: EreborOrthographyStore,
    ) {
        self.assetProvider = nil
        self.engineFactory = TranslationEngineFactory(
            elderEngine: ElderFutharkTranslationEngine(
                lexiconStore: lexiconStore,
                runicCorpusStore: runicCorpusStore,
            ),
            youngerEngine: YoungerFutharkTranslationEngine(
                lexiconStore: lexiconStore,
                runicCorpusStore: runicCorpusStore,
            ),
            cirthEngine: EreborCirthTranslationEngine(
                runicCorpusStore: runicCorpusStore,
                ereborStore: ereborStore,
            ),
        )
    }

    init(datasetProvider: AssetTranslationDatasetProvider = AssetTranslationDatasetProvider()) {
        self.assetProvider = datasetProvider
        self.engineFactory = TranslationEngineFactory(
            elderEngine: ElderFutharkTranslationEngine(
                lexiconStore: datasetProvider,
                runicCorpusStore: datasetProvider,
            ),
            youngerEngine: YoungerFutharkTranslationEngine(
                lexiconStore: datasetProvider,
                runicCorpusStore: datasetProvider,
            ),
            cirthEngine: EreborCirthTranslationEngine(
                runicCorpusStore: datasetProvider,
                ereborStore: datasetProvider,
            ),
        )
    }

    var versionSignature: String {
        [
            self.engineFactory.create(.elder).engineVersion,
            self.engineFactory.create(.younger).engineVersion,
            self.engineFactory.create(.cirth).engineVersion,
        ].joined(separator: "|")
    }

    var datasetVersion: String {
        self.engineFactory.create(.elder).datasetVersion
    }

    func warmUp() {
        self.assetProvider?.warmUp()
    }

    func translate(
        _ request: TranslationRequest,
    ) -> TranslationResult {
        let resolvedLanguage = TranslationSourceLanguageDetector.detect(
            text: request.sourceText,
            requested: request.sourceLanguage,
        )
        let normalizedRequest = TranslationRequest(
            sourceText: request.sourceText,
            script: request.script,
            fidelity: request.fidelity,
            youngerVariant: request.youngerVariant,
            sourceLanguage: resolvedLanguage,
            evidenceCap: request.evidenceCap,
        )

        guard resolvedLanguage.isSupported else {
            return self.unsupportedLanguageResult(for: normalizedRequest)
        }

        return self.engineFactory.create(request.script).translate(normalizedRequest)
    }

    func translate(
        text: String,
        script: RunicScript,
        fidelity: TranslationFidelity = .default,
        youngerVariant: YoungerFutharkVariant = .default,
        sourceLanguage: TranslationSourceLanguage = .english,
        evidenceCap: TranslationEvidenceCap = .fullDataset,
    ) -> TranslationResult {
        self.translate(
            TranslationRequest(
                sourceText: text,
                script: script,
                fidelity: fidelity,
                youngerVariant: youngerVariant,
                sourceLanguage: sourceLanguage,
                evidenceCap: evidenceCap,
            ),
        )
    }

    func translateAllAvailable(
        text: String,
        fidelity: TranslationFidelity = .default,
        youngerVariant: YoungerFutharkVariant = .default,
        sourceLanguage: TranslationSourceLanguage = .english,
        evidenceCap: TranslationEvidenceCap = .fullDataset,
    ) -> [TranslationResult] {
        RunicScript.allCases.map {
            self.translate(
                text: text,
                script: $0,
                fidelity: fidelity,
                youngerVariant: youngerVariant,
                sourceLanguage: sourceLanguage,
                evidenceCap: evidenceCap,
            )
        }
    }

    private func unsupportedLanguageResult(for request: TranslationRequest) -> TranslationResult {
        TranslationResult(
            sourceText: request.sourceText,
            script: request.script,
            fidelity: request.fidelity,
            derivationKind: .tokenComposed,
            historicalStage: .modernEnglish,
            normalizedForm: "",
            diplomaticForm: "",
            glyphOutput: "",
            requestedVariant: request.script == .younger ? request.youngerVariant.rawValue : nil,
            resolutionStatus: .unavailable,
            supportLevel: .unsupported,
            evidenceTier: .unsupported,
            confidence: 0,
            notes: ["Historical translation currently supports English source text only."],
            unresolvedTokens: [],
            provenance: [],
            tokenBreakdown: [],
            attestationRefs: [],
            inputLanguage: .unsupported,
            userFacingWarnings: [
                "Translation currently supports English input only.",
                "Use transliteration mode for non-English text.",
            ],
            engineVersion: self.versionSignature,
            datasetVersion: self.datasetVersion,
        )
    }
}

private struct TranslationEngineFactory {
    let elderEngine: ElderFutharkTranslationEngine
    let youngerEngine: YoungerFutharkTranslationEngine
    let cirthEngine: EreborCirthTranslationEngine

    func create(_ script: RunicScript) -> any TranslationEngine {
        switch script {
        case .elder:
            self.elderEngine
        case .younger:
            self.youngerEngine
        case .cirth:
            self.cirthEngine
        }
    }
}

// MARK: - Engines

private struct YoungerFutharkTranslationEngine: TranslationEngine {
    let script: RunicScript = .younger
    let engineVersion = "yf-translation-v4"

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
            corpusReferences: runicCorpusStore.runicCorpusReferences(),
        )
        let lookup = HistoricalLexiconLookup(lexiconStore: lexiconStore, sourceCatalog: catalog)
        self.sourceCatalog = catalog
        self.goldExampleResolver = TranslationGoldExampleResolver(runicCorpusStore: runicCorpusStore)
        self.phraseTemplateResolver = RunicPhraseTemplateResolver(
            runicCorpusStore: runicCorpusStore,
            sourceCatalog: catalog,
        )
        self.lexiconLookup = lookup
        self.morphologyStage = OldNorseMorphologyStage(lexiconLookup: lookup)
        self.evidenceSynthesizer = TranslationEvidenceSynthesizer(datasetVersion: lookup.datasetVersion())
        self.datasetVersion = lookup.datasetVersion()
    }

    func translate(_ request: TranslationRequest) -> TranslationResult {
        if let gold = goldExampleResolver.resolve(
            request: request,
            engineVersion: engineVersion,
        ) {
            return gold
        }
        if let template = phraseTemplateResolver.resolveYounger(
            request: request,
            renderer: renderer,
        ) {
            return template.withEngineVersion(self.engineVersion)
        }

        let grammarRules = self.lexiconLookup.grammarRules()
        let parsed = self.parser.parse(
            request.sourceText,
            grammarRules: grammarRules,
            recognizedTerms: self.lexiconLookup.recognizedEnglishTerms(),
            multiwordExpressions: self.lexiconLookup.multiwordExpressions(),
        )
        let resolutions = parsed.tokens.compactMap { token -> TranslationTokenResolution? in
            if token.type == .punctuation {
                return token.asPunctuationResolution()
            }
            if grammarRules.removableWords.contains(token.normalized) {
                return nil
            }
            return self.resolveToken(token, request: request)
        }

        return self.evidenceSynthesizer.buildResult(
            request: request,
            resolutions: resolutions,
            evidenceRequest: TranslationEvidenceRequest(
                script: self.script,
                derivationKind: .tokenComposed,
                historicalStage: .oldNorse,
                engineVersion: self.engineVersion,
                requestedVariant: request.youngerVariant.rawValue,
                baseConfidence: youngerBaseConfidence(for: request.fidelity),
                fallbackStatus: .reconstructed,
                defaultNote: "Generated using the offline Old Norse translation pipeline.",
                analysisWarnings: parsed.warnings,
                inputLanguage: request.sourceLanguage,
            ),
        )
    }

    private func resolveToken(
        _ token: ParsedEnglishToken,
        request: TranslationRequest,
    ) -> TranslationTokenResolution {
        var provenance: [TranslationProvenanceEntry] = []
        var notes: [String] = []
        var resolutionStatus: TranslationResolutionStatus = .reconstructed

        let normalized: String
        if let pronoun = lexiconLookup.grammarRules().pronounMap[token.normalized] {
            provenance.append(
                self.lexiconLookup.provenanceFor(
                    sourceID: "internal_heuristics",
                    detail: "Pronoun mapping",
                ),
            )
            normalized = pronoun
        } else if let preposition = lexiconLookup.grammarRules().prepositionMap[token.normalized] {
            provenance.append(
                self.lexiconLookup.provenanceFor(
                    sourceID: "internal_heuristics",
                    detail: "Preposition mapping",
                ),
            )
            normalized = preposition
        } else if let name = lexiconLookup.resolveName(token.normalized) {
            provenance.append(
                self.lexiconLookup.provenanceFor(
                    sourceID: "internal_heuristics",
                    detail: "Curated name adaptation",
                ),
            )
            normalized = name
        } else if token.isProperNameCandidate, request.fidelity != .strict {
            resolutionStatus = .approximated
            notes.append("Preserved an uncatalogued proper name phonetically.")
            provenance.append(
                self.lexiconLookup.provenanceFor(
                    sourceID: "internal_heuristics",
                    detail: "Proper-name preservation fallback",
                ),
            )
            normalized = token.normalized
        } else if let entry = lexiconLookup.oldNorseFor(
            token.normalized,
            fidelity: request.fidelity,
            evidenceCap: request.evidenceCap,
        ) {
            resolutionStatus = entry.attestationStatus == .attested ? .attested : .reconstructed
            provenance.append(self.lexiconLookup.provenanceFor(entry: entry))
            let morphology = self.morphologyStage.inflect(entry: entry, token: token)
            notes.append(contentsOf: morphology.notes)
            normalized = morphology.form
        } else if request.fidelity != .strict, let paraphrase = lexiconLookup.fallbackParaphrase(token.normalized) {
            resolutionStatus = .approximated
            notes.append("Used descriptive paraphrase for '\(token.raw)'.")
            provenance.append(
                self.lexiconLookup.provenanceFor(
                    sourceID: "internal_heuristics",
                    detail: "Readable-mode paraphrase",
                ),
            )
            normalized = paraphrase
        } else if request.fidelity != .strict {
            resolutionStatus = .approximated
            notes.append(
                request.fidelity == .decorative
                    ? "Decorative mode preserved '\(token.raw)' phonetically."
                    : "Readable mode preserved '\(token.raw)' phonetically.",
            )
            provenance.append(
                self.lexiconLookup.provenanceFor(
                    sourceID: "internal_heuristics",
                    detail: "Phonological preservation fallback",
                ),
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
                unresolvedToken: token.raw,
            )
        }

        let phonology = self.phonologyStage.rewrite(normalized)
        notes.append(contentsOf: phonology.notes)
        let diplomatic = phonology.form
        let glyph = self.renderer.render(diplomatic, variant: request.youngerVariant)

        return TranslationTokenResolution(
            sourceToken: token.raw,
            normalizedToken: normalized,
            diplomaticToken: diplomatic,
            glyphToken: glyph,
            resolutionStatus: resolutionStatus,
            notes: Array(Set(notes)),
            provenance: provenance.uniquedBy(\.stableID),
        )
    }
}

private struct ElderFutharkTranslationEngine: TranslationEngine {
    let script: RunicScript = .elder
    let engineVersion = "ef-translation-v4"

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
            corpusReferences: runicCorpusStore.runicCorpusReferences(),
        )
        let lookup = HistoricalLexiconLookup(lexiconStore: lexiconStore, sourceCatalog: sourceCatalog)
        self.goldExampleResolver = TranslationGoldExampleResolver(runicCorpusStore: runicCorpusStore)
        self.phraseTemplateResolver = RunicPhraseTemplateResolver(
            runicCorpusStore: runicCorpusStore,
            sourceCatalog: sourceCatalog,
        )
        self.lexiconLookup = lookup
        self.lexicalStage = ProtoNorseLexicalStage(lexiconLookup: lookup)
        self.evidenceSynthesizer = TranslationEvidenceSynthesizer(datasetVersion: lookup.datasetVersion())
        self.datasetVersion = lookup.datasetVersion()
    }

    func translate(_ request: TranslationRequest) -> TranslationResult {
        if let gold = goldExampleResolver.resolve(
            request: request,
            engineVersion: engineVersion,
        ) {
            return gold
        }
        if let template = phraseTemplateResolver.resolveElder(
            request: request,
            renderer: renderer,
        ) {
            return template.withEngineVersion(self.engineVersion)
        }

        let parsed = self.parser.parse(
            request.sourceText,
            grammarRules: self.lexiconLookup.grammarRules(),
            recognizedTerms: self.lexiconLookup.recognizedEnglishTerms(),
            multiwordExpressions: self.lexiconLookup.multiwordExpressions(),
        )
        if request.fidelity == .strict {
            return self.strictUnavailableResult(request, warnings: parsed.warnings)
        }

        let resolutions = parsed.tokens.map { token in
            if token.type == .punctuation {
                return token.asPunctuationResolution()
            }

            let output = self.lexicalStage.reconstruct(token: token, fidelity: request.fidelity, evidenceCap: request.evidenceCap)
            if let unresolved = output.unresolvedToken {
                return TranslationTokenResolution(
                    sourceToken: token.raw,
                    normalizedToken: "",
                    diplomaticToken: "",
                    glyphToken: "",
                    resolutionStatus: .unavailable,
                    notes: output.notes,
                    unresolvedToken: unresolved,
                )
            }

            let normalized = output.form ?? ""
            return TranslationTokenResolution(
                sourceToken: token.raw,
                normalizedToken: normalized,
                diplomaticToken: normalized,
                glyphToken: self.renderer.render(normalized),
                resolutionStatus: output.resolutionStatus,
                notes: output.notes,
                provenance: output.provenance,
            )
        }

        return self.evidenceSynthesizer.buildResult(
            request: request,
            resolutions: resolutions,
            evidenceRequest: TranslationEvidenceRequest(
                script: self.script,
                derivationKind: .tokenComposed,
                historicalStage: .protoNorse,
                engineVersion: self.engineVersion,
                baseConfidence: elderBaseConfidence(for: request.fidelity),
                fallbackStatus: .reconstructed,
                defaultNote: "Generated using the offline Proto-Norse translation pipeline.",
                analysisWarnings: parsed.warnings,
                inputLanguage: request.sourceLanguage,
            ),
        )
    }

    private func strictUnavailableResult(_ request: TranslationRequest, warnings: [String]) -> TranslationResult {
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
            supportLevel: .unsupported,
            evidenceTier: .unsupported,
            confidence: 0,
            notes: ["Missing attested or reconstructed Elder Futhark pattern for this phrase."],
            unresolvedTokens: request.sourceText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? []
                : [request.sourceText.trimmingCharacters(in: .whitespacesAndNewlines)],
            provenance: [],
            tokenBreakdown: [],
            attestationRefs: [],
            inputLanguage: request.sourceLanguage,
            userFacingWarnings: warnings,
            engineVersion: self.engineVersion,
            datasetVersion: self.datasetVersion,
        )
    }
}

private struct EreborCirthTranslationEngine: TranslationEngine {
    let script: RunicScript = .cirth
    let engineVersion = "cirth-translation-v4"

    private let parser = EnglishSyntaxParser()
    private let goldExampleResolver: TranslationGoldExampleResolver
    private let tokenizer: CirthOrthographyStage
    private let evidenceSynthesizer: TranslationEvidenceSynthesizer
    let datasetVersion: String

    init(runicCorpusStore: RunicCorpusStore, ereborStore: EreborOrthographyStore) {
        let sourceCatalog = HistoricalSourceCatalog(
            sourceManifest: ereborStore.sourceManifest(),
            corpusReferences: runicCorpusStore.runicCorpusReferences(),
        )
        self.goldExampleResolver = TranslationGoldExampleResolver(
            runicCorpusStore: runicCorpusStore,
            cirthRenderer: CirthFontRenderer(wordSeparator: ereborStore.ereborTables().wordSeparator),
        )
        self.tokenizer = CirthOrthographyStage(
            ereborStore: ereborStore,
            sourceCatalog: sourceCatalog,
        )
        self.evidenceSynthesizer = TranslationEvidenceSynthesizer(datasetVersion: ereborStore.datasetManifest().version)
        self.datasetVersion = ereborStore.datasetManifest().version
    }

    func translate(_ request: TranslationRequest) -> TranslationResult {
        if let gold = goldExampleResolver.resolve(
            request: request,
            engineVersion: engineVersion,
        ) {
            return gold
        }
        if let phrase = tokenizer.resolvePhrase(request: request) {
            return phrase.with(
                engineVersion: self.engineVersion,
                datasetVersion: self.datasetVersion,
            )
        }

        let parsed = self.parser.parse(request.sourceText)
        let resolutions = parsed.tokens.map { token in
            if token.type == .punctuation {
                return token.asPunctuationResolution()
            }

            let output = self.tokenizer.renderToken(token: token.normalized, fidelity: request.fidelity)
            if let unresolved = output.unresolvedToken {
                return TranslationTokenResolution(
                    sourceToken: token.raw,
                    normalizedToken: "",
                    diplomaticToken: "",
                    glyphToken: "",
                    resolutionStatus: .unavailable,
                    notes: output.notes,
                    unresolvedToken: unresolved,
                )
            }

            return TranslationTokenResolution(
                sourceToken: token.raw,
                normalizedToken: token.normalized,
                diplomaticToken: output.diplomatic ?? "",
                glyphToken: output.glyphs ?? "",
                resolutionStatus: output.resolutionStatus,
                notes: output.notes,
                provenance: output.provenance,
            )
        }

        return self.evidenceSynthesizer.buildResult(
            request: request,
            resolutions: resolutions,
            evidenceRequest: TranslationEvidenceRequest(
                script: self.script,
                derivationKind: .sequenceTranscription,
                historicalStage: .ereborEnglish,
                engineVersion: self.engineVersion,
                baseConfidence: cirthBaseConfidence(for: request.fidelity),
                fallbackStatus: .reconstructed,
                defaultNote: "Generated using the offline Erebor transcription pipeline.",
                analysisWarnings: parsed.warnings,
                inputLanguage: request.sourceLanguage,
            ),
        )
    }
}

// MARK: - Parsing

private struct EnglishSyntaxParser {
    func parse(_ text: String) -> ParsedEnglishText {
        self.parse(
            text,
            grammarRules: .empty,
            recognizedTerms: [],
            multiwordExpressions: [],
        )
    }

    func parse(_ text: String, lexiconLookup: HistoricalLexiconLookup) -> ParsedEnglishText {
        self.parse(
            text,
            grammarRules: lexiconLookup.grammarRules(),
            recognizedTerms: lexiconLookup.recognizedEnglishTerms(),
            multiwordExpressions: lexiconLookup.multiwordExpressions(),
        )
    }

    func parse(
        _ text: String,
        grammarRules: GrammarRulesData,
        recognizedTerms: Set<String>,
        multiwordExpressions: [String],
    ) -> ParsedEnglishText {
        let normalizedText = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)

        var warnings = [String]()

        let rawTokens = self.tokenRegex
            .matches(in: normalizedText, range: NSRange(normalizedText.startIndex..., in: normalizedText))
            .compactMap { Range($0.range, in: normalizedText).map { normalizedText[$0] } }
            .map(String.init)
            .flatMap { self.expandContractions(in: $0, warnings: &warnings, pronouns: Set(grammarRules.pronounMap.keys)) }
            .map { value in
                ParsedEnglishToken(
                    raw: value,
                    normalized: value.lowercased(),
                    type: value.allSatisfy { $0.isLetter || $0 == "'" } ? .word : .punctuation,
                    isProperNameCandidate: value.first?.isUppercase == true,
                )
            }

        let mergedTokens = self.mergeMultiwordExpressions(
            in: rawTokens,
            phrases: multiwordExpressions,
        )

        var tokens = [ParsedEnglishToken]()
        tokens.reserveCapacity(mergedTokens.count)

        for (index, token) in mergedTokens.enumerated() {
            guard token.type == .word else {
                tokens.append(token)
                continue
            }

            var normalized = token.normalized
            if let strippedPossessive = stripPossessive(normalized), strippedPossessive != normalized {
                normalized = strippedPossessive
                warnings.append("Possessive constructions are currently simplified to bare nouns.")
            }

            if let auxiliaryLemma = grammarRules.auxiliaryMap[normalized] {
                if self.collapsibleAuxiliaries.contains(normalized),
                   self.hasFollowingContentWord(after: index, in: mergedTokens)
                {
                    warnings.append("Auxiliary chains are simplified to the main lexical verb.")
                    continue
                }
                normalized = auxiliaryLemma
            }

            if let negationLemma = grammarRules.negationMap[normalized] {
                normalized = negationLemma
            }

            tokens.append(
                ParsedEnglishToken(
                    raw: token.raw,
                    normalized: normalized,
                    type: token.type,
                    isProperNameCandidate: token.isProperNameCandidate,
                ),
            )
        }

        let firstVerbIndex = tokens.firstIndex {
            $0.type == .word && self.isVerbLike($0, grammarRules: grammarRules)
        } ?? tokens.count
        let firstPrepositionIndex = tokens.firstIndex {
            self.commonPrepositions.contains($0.normalized) || grammarRules.prepositionMap[$0.normalized] != nil
        }

        if firstVerbIndex == 0,
           let firstWord = tokens.first,
           firstWord.type == .word,
           !grammarRules.pronounMap.keys.contains(firstWord.normalized),
           !grammarRules.removableWords.contains(firstWord.normalized)
        {
            warnings.append("Imperative readings are handled conservatively and may stay approximate.")
        }

        if tokens.contains(where: { $0.isProperNameCandidate && !recognizedTerms.contains($0.normalized) }) {
            warnings.append("Uncurated proper names may be preserved phonetically.")
        }

        return ParsedEnglishText(
            originalText: text,
            normalizedText: normalizedText,
            tokens: tokens,
            subjectTokens: tokens.safeSlice(from: 0, to: firstVerbIndex),
            verbTokens: firstVerbIndex < tokens.count ? [tokens[firstVerbIndex]] : [],
            modifierTokens: firstPrepositionIndex.map { Array(tokens.dropFirst($0)) } ?? [],
            warnings: Array(Set(warnings)),
        )
    }

    private func expandContractions(
        in token: String,
        warnings: inout [String],
        pronouns: Set<String>,
    ) -> [String] {
        let normalized = token.lowercased()
        if self.punctuationCharacters.contains(normalized) {
            return [token]
        }

        if normalized == "won't" {
            warnings.append("Expanded an English contraction for analysis.")
            return ["will", "not"]
        }
        if normalized == "can't" {
            warnings.append("Expanded an English contraction for analysis.")
            return ["can", "not"]
        }
        if normalized.hasSuffix("n't"), normalized.count > 3 {
            warnings.append("Expanded an English contraction for analysis.")
            return [String(normalized.dropLast(3)), "not"]
        }

        guard let apostropheIndex = normalized.firstIndex(of: "'") else {
            return [token]
        }

        let prefix = String(normalized[..<apostropheIndex])
        let suffix = String(normalized[normalized.index(after: apostropheIndex)...])

        switch suffix {
        case "re":
            warnings.append("Expanded an English contraction for analysis.")
            return [prefix, "are"]
        case "m":
            warnings.append("Expanded an English contraction for analysis.")
            return [prefix, "am"]
        case "ve":
            warnings.append("Expanded an English contraction for analysis.")
            return [prefix, "have"]
        case "ll":
            warnings.append("Expanded an English contraction for analysis.")
            return [prefix, "will"]
        case "d":
            warnings.append("Expanded an English contraction for analysis.")
            return [prefix, "would"]
        case "s" where pronouns.contains(prefix):
            warnings.append("Expanded an English contraction for analysis.")
            return [prefix, "is"]
        default:
            return [token]
        }
    }

    private func mergeMultiwordExpressions(
        in tokens: [ParsedEnglishToken],
        phrases: [String],
    ) -> [ParsedEnglishToken] {
        let phraseParts = phrases.map { $0.split(separator: " ").map(String.init) }
        var merged = [ParsedEnglishToken]()
        var index = 0

        while index < tokens.count {
            let token = tokens[index]
            guard token.type == .word else {
                merged.append(token)
                index += 1
                continue
            }

            var matchedPhrase: [String]?
            for parts in phraseParts where index + parts.count <= tokens.count {
                let slice = Array(tokens[index ..< (index + parts.count)])
                guard slice.allSatisfy({ $0.type == .word }) else { continue }
                if zip(slice.map(\.normalized), parts).allSatisfy(==) {
                    matchedPhrase = parts
                    break
                }
            }

            if let matchedPhrase {
                let rawPhrase = tokens[index ..< (index + matchedPhrase.count)].map(\.raw).joined(separator: " ")
                merged.append(
                    ParsedEnglishToken(
                        raw: rawPhrase,
                        normalized: matchedPhrase.joined(separator: " "),
                        type: .word,
                        isProperNameCandidate: false,
                    ),
                )
                index += matchedPhrase.count
            } else {
                merged.append(token)
                index += 1
            }
        }

        return merged
    }

    private func stripPossessive(_ token: String) -> String? {
        if token.hasSuffix("'s") {
            return String(token.dropLast(2))
        }
        if token.hasSuffix("s'") {
            return String(token.dropLast())
        }
        return nil
    }

    private func hasFollowingContentWord(after index: Int, in tokens: [ParsedEnglishToken]) -> Bool {
        tokens.dropFirst(index + 1).contains { $0.type == .word }
    }

    private func isVerbLike(_ token: ParsedEnglishToken, grammarRules: GrammarRulesData) -> Bool {
        let raw = token.rawLowercased
        return raw.hasSuffix("s") ||
            raw.hasSuffix("ed") ||
            raw.hasSuffix("ing") ||
            grammarRules.auxiliaryMap[token.normalized] != nil ||
            grammarRules.imperativeHints.contains(token.normalized)
    }

    private let tokenRegex = (try? NSRegularExpression(pattern: #"[A-Za-z']+|[.,!?;:-]"#))
        ?? NSRegularExpression()
    private let punctuationCharacters = Set([".", ",", "!", "?", ";", ":", "-"])
    private let collapsibleAuxiliaries = Set(["do", "does", "did", "have", "has", "had", "will", "would", "shall", "should", "can", "could", "may", "might", "must"])
    private let commonPrepositions = Set(["at", "in", "on", "under", "with", "for", "from", "to", "of"])
}

private struct ParsedEnglishText {
    let originalText: String
    let normalizedText: String
    let tokens: [ParsedEnglishToken]
    let subjectTokens: [ParsedEnglishToken]
    let verbTokens: [ParsedEnglishToken]
    let modifierTokens: [ParsedEnglishToken]
    let warnings: [String]
}

private struct ParsedEnglishToken {
    let raw: String
    let normalized: String
    let type: ParsedEnglishTokenType
    let isProperNameCandidate: Bool

    var rawLowercased: String {
        self.raw.lowercased()
    }
}

private enum ParsedEnglishTokenType {
    case word
    case punctuation
}

private extension GrammarRulesData {
    static let empty = GrammarRulesData(
        removableWords: [],
        prepositionMap: [:],
        interrogatives: [],
        pronounMap: [:],
        auxiliaryMap: [:],
        negationMap: [:],
        multiwordExpressions: [],
        imperativeHints: [],
        englishFunctionWords: [],
    )
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

        let resolvedEvidenceTier = TranslationEvidenceTier(rawValue: result.evidenceTierRaw ?? "")
            ?? TranslationResult.defaultEvidenceTier(
                for: TranslationResolutionStatus(rawValue: result.resolutionStatus) ?? .unavailable,
            )
        if request.evidenceCap == .attestedOnly, resolvedEvidenceTier != .attested {
            return nil
        }

        let tokenBreakdown = result.tokenBreakdown.map { token in
            let glyphToken: String = if request.script == .cirth, let cirthRenderer {
                cirthRenderer.render(diplomatic: token.diplomaticToken)
            } else if request.script == .younger, request.youngerVariant == .shortTwig {
                YoungerFutharkRenderer().render(token.diplomaticToken, variant: .shortTwig)
            } else {
                token.glyphToken
            }

            return TranslationTokenBreakdown(
                sourceToken: token.sourceToken,
                normalizedToken: token.normalizedToken,
                diplomaticToken: token.diplomaticToken,
                glyphToken: glyphToken,
                resolutionStatus: token.resolutionStatus,
                provenance: token.provenance,
            )
        }

        let glyphOutput: String = if request.script == .cirth, let cirthRenderer {
            cirthRenderer.render(diplomatic: result.diplomaticForm)
        } else if request.script == .younger, request.youngerVariant == .shortTwig {
            YoungerFutharkRenderer().render(result.diplomaticForm, variant: .shortTwig)
        } else {
            result.glyphOutput
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
            supportLevel: TranslationSupportLevel(rawValue: result.supportLevelRaw ?? "")
                ?? TranslationResult.defaultSupportLevel(
                    for: TranslationResolutionStatus(rawValue: result.resolutionStatus) ?? .unavailable,
                ),
            evidenceTier: resolvedEvidenceTier,
            confidence: result.confidence,
            notes: result.notes,
            unresolvedTokens: result.unresolvedTokens,
            provenance: result.provenance,
            tokenBreakdown: tokenBreakdown,
            attestationRefs: result.attestationRefs.isEmpty
                ? result.provenance.compactMap(\.referenceID).uniqued()
                : result.attestationRefs,
            inputLanguage: TranslationSourceLanguage(rawValue: result.inputLanguageRaw ?? "") ?? request.sourceLanguage,
            userFacingWarnings: result.userFacingWarnings,
            engineVersion: engineVersion,
            datasetVersion: self.runicCorpusStore.datasetManifest().version,
        )
    }
}

private struct HistoricalSourceCatalog {
    private let sourceEntries: [String: TranslationSourceEntry]
    private let corpusReferences: [String: RunicCorpusReferenceEntry]

    init(sourceManifest: TranslationSourceManifest, corpusReferences: [RunicCorpusReferenceEntry] = []) {
        self.sourceEntries = Dictionary(uniqueKeysWithValues: sourceManifest.sources.map { ($0.id, $0) })
        self.corpusReferences = Dictionary(uniqueKeysWithValues: corpusReferences.map { ($0.id, $0) })
    }

    func provenanceFor(
        sourceID: String,
        referenceID: String? = nil,
        detail: String? = nil,
        sourceWork: String? = nil,
        attestationStatus: TranslationAttestationStatus? = nil,
        lemmaAuthorityID: String? = nil,
        grammaticalClass: String? = nil,
        historicalStage: String? = nil,
        licenseNote: String? = nil,
        regressionID: String? = nil,
    ) -> TranslationProvenanceEntry {
        let source = self.sourceEntries[sourceID]
            ?? self.sourceEntries["internal_heuristics"]
            ?? TranslationSourceEntry(
                id: "internal_heuristics",
                name: "Runatal heuristics",
                role: "Offline fallback logic and generated educational notes",
                work: nil,
                license: "Project-owned",
                licenseNote: nil,
                url: "https://github.com/po4yka/runatal-ios",
            )
        let reference = referenceID.flatMap { self.corpusReferences[$0] }
        return TranslationProvenanceEntry(
            sourceID: source.id,
            referenceID: referenceID,
            label: reference?.label ?? source.name,
            role: source.role,
            license: source.license,
            sourceWork: sourceWork ?? reference?.sourceWork ?? source.work,
            licenseNote: licenseNote ?? reference?.licenseNote ?? source.licenseNote,
            attestationStatus: attestationStatus ?? reference?.attestationStatus,
            lemmaAuthorityID: lemmaAuthorityID,
            grammaticalClass: grammaticalClass,
            historicalStage: historicalStage ?? reference?.historicalStage,
            regressionID: regressionID ?? reference?.regressionID,
            detail: detail ?? reference?.detail,
            url: reference?.url ?? source.url,
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
        self.oldNorseEntries = Dictionary(
            uniqueKeysWithValues: lexiconStore.oldNorseLexicon().map { ($0.english.lowercased(), $0) },
        )
        self.protoNorseEntries = Dictionary(
            uniqueKeysWithValues: lexiconStore.protoNorseLexicon().map { ($0.english.lowercased(), $0) },
        )
    }

    func datasetVersion() -> String {
        self.lexiconStore.datasetManifest().version
    }

    func oldNorseFor(
        _ token: String,
        fidelity: TranslationFidelity,
        evidenceCap: TranslationEvidenceCap,
    ) -> OldNorseLexiconEntry? {
        let normalized = self.resolveSynonym(token)
        guard let entry = oldNorseEntries[normalized] else { return nil }
        if fidelity == .strict && (!entry.strictEligible || !entry.inventory.isStrictEligible) {
            return nil
        }
        if evidenceCap == .attestedOnly && entry.attestationStatus != .attested {
            return nil
        }
        return entry
    }

    func protoNorseFor(
        _ token: String,
        fidelity: TranslationFidelity,
        evidenceCap: TranslationEvidenceCap,
    ) -> ProtoNorseLexiconEntry? {
        let normalized = self.resolveSynonym(token)
        guard let entry = protoNorseEntries[normalized] else { return nil }
        if fidelity == .strict && (!entry.strictEligible || !entry.inventory.isStrictEligible) {
            return nil
        }
        if evidenceCap == .attestedOnly && entry.attestationStatus != .attested {
            return nil
        }
        return entry
    }

    func resolveName(_ token: String) -> String? {
        self.lexiconStore.nameAdaptations().names[token]
    }

    func fallbackParaphrase(_ token: String) -> String? {
        self.lexiconStore.fallbackTemplates().paraphrases[token]
    }

    func fallbackSynonym(_ token: String) -> String? {
        self.lexiconStore.fallbackTemplates().synonyms[token]
    }

    func grammarRules() -> GrammarRulesData {
        self.lexiconStore.grammarRules()
    }

    func paradigmTables() -> ParadigmTablesData {
        self.lexiconStore.paradigmTables()
    }

    func provenanceFor(entry: OldNorseLexiconEntry) -> TranslationProvenanceEntry {
        self.sourceCatalog.provenanceFor(
            sourceID: entry.sourceID,
            referenceID: entry.id,
            detail: entry.citations.joined(separator: ", ").nilIfEmpty,
            sourceWork: entry.sourceWork,
            attestationStatus: entry.attestationStatus,
            lemmaAuthorityID: entry.lemmaAuthorityID,
            grammaticalClass: entry.grammaticalClass ?? entry.partOfSpeech,
            historicalStage: entry.historicalStage,
            licenseNote: entry.licenseNote,
            regressionID: entry.regressionID,
        )
    }

    func provenanceFor(entry: ProtoNorseLexiconEntry) -> TranslationProvenanceEntry {
        self.sourceCatalog.provenanceFor(
            sourceID: entry.sourceID,
            referenceID: entry.id,
            detail: entry.citations.joined(separator: ", ").nilIfEmpty,
            sourceWork: entry.sourceWork,
            attestationStatus: entry.attestationStatus,
            lemmaAuthorityID: entry.lemmaAuthorityID,
            grammaticalClass: entry.grammaticalClass ?? entry.partOfSpeech,
            historicalStage: entry.historicalStage,
            licenseNote: entry.licenseNote,
            regressionID: entry.regressionID,
        )
    }

    func provenanceFor(sourceID: String, referenceID: String? = nil, detail: String? = nil) -> TranslationProvenanceEntry {
        self.sourceCatalog.provenanceFor(sourceID: sourceID, referenceID: referenceID, detail: detail)
    }

    func multiwordExpressions() -> [String] {
        let derived = self.oldNorseEntries.keys.filter { $0.contains(" ") } + self.protoNorseEntries.keys.filter { $0.contains(" ") }
        let configured = self.lexiconStore.grammarRules().multiwordExpressions
        return Array(Set(derived + configured)).sorted {
            $0.split(separator: " ").count > $1.split(separator: " ").count
        }
    }

    func recognizedEnglishTerms() -> Set<String> {
        let grammarRules = self.lexiconStore.grammarRules()
        var terms = Array(oldNorseEntries.keys)
        terms.append(contentsOf: self.protoNorseEntries.keys)
        terms.append(contentsOf: self.lexiconStore.fallbackTemplates().synonyms.keys)
        terms.append(contentsOf: self.lexiconStore.fallbackTemplates().paraphrases.keys)
        terms.append(contentsOf: self.lexiconStore.nameAdaptations().names.keys)
        terms.append(contentsOf: grammarRules.pronounMap.keys)
        terms.append(contentsOf: grammarRules.prepositionMap.keys)
        terms.append(contentsOf: grammarRules.negationMap.keys)
        terms.append(contentsOf: grammarRules.auxiliaryMap.keys)
        terms.append(contentsOf: grammarRules.removableWords)
        terms.append(contentsOf: grammarRules.interrogatives)
        terms.append(contentsOf: grammarRules.multiwordExpressions)
        terms.append(contentsOf: grammarRules.englishFunctionWords)
        return Set(terms)
    }

    private func resolveSynonym(_ token: String) -> String {
        self.lexiconStore.fallbackTemplates().synonyms[token] ?? token
    }
}

private struct RunicPhraseTemplateResolver {
    let runicCorpusStore: RunicCorpusStore
    let sourceCatalog: HistoricalSourceCatalog

    func resolveYounger(
        request: TranslationRequest,
        renderer: YoungerFutharkRenderer,
    ) -> TranslationResult? {
        guard let template = findTemplate(request: request, templates: runicCorpusStore.youngerPhraseTemplates()) else {
            return nil
        }
        return self.toTranslationResult(
            template: template,
            request: request,
            script: .younger,
            datasetVersion: self.runicCorpusStore.datasetManifest().version,
            engineVersion: "yf-template-v4",
        ) { renderer.render($0, variant: request.youngerVariant) }
    }

    func resolveElder(
        request: TranslationRequest,
        renderer: ElderRuneRenderer,
    ) -> TranslationResult? {
        guard let template = findTemplate(request: request, templates: runicCorpusStore.elderAttestedForms()) else {
            return nil
        }
        return self.toTranslationResult(
            template: template,
            request: request,
            script: .elder,
            datasetVersion: self.runicCorpusStore.datasetManifest().version,
            engineVersion: "ef-template-v4",
        ) { renderer.render($0) }
    }

    private func findTemplate(
        request: TranslationRequest,
        templates: [HistoricalPhraseTemplateEntry],
    ) -> HistoricalPhraseTemplateEntry? {
        let candidates = templates.filter {
            $0.script == request.script.translationScriptName &&
                $0.sourceText.normalizePhraseKey() == request.sourceText.normalizePhraseKey()
        }
        let eligibleCandidates = candidates.filter {
            request.evidenceCap != .attestedOnly || $0.attestationStatus == .attested
        }
        return eligibleCandidates.first(where: { $0.fidelity == request.fidelity.rawValue }) ??
            eligibleCandidates.first(where: { $0.fidelity == TranslationFidelity.strict.rawValue })
    }

    private func toTranslationResult(
        template: HistoricalPhraseTemplateEntry,
        request: TranslationRequest,
        script: RunicScript,
        datasetVersion: String,
        engineVersion: String,
        glyphRenderer: (String) -> String,
    ) -> TranslationResult {
        let referencesByID = Dictionary(
            uniqueKeysWithValues: runicCorpusStore.runicCorpusReferences().map { ($0.id, $0) },
        )
        let provenance = template.referenceIDs.map { referenceID in
            let sourceID = referencesByID[referenceID]?.sourceID ?? "internal_heuristics"
            return self.sourceCatalog.provenanceFor(
                sourceID: sourceID,
                referenceID: referenceID,
                sourceWork: template.sourceWork,
                attestationStatus: template.attestationStatus,
                historicalStage: template.historicalStage,
                licenseNote: template.licenseNote,
                regressionID: template.regressionID,
            )
        }
        let breakdown = template.tokenBreakdown.map { token in
            let tokenProvenance = token.referenceIDs.map { referenceID in
                let sourceID = referencesByID[referenceID]?.sourceID ?? "internal_heuristics"
                return self.sourceCatalog.provenanceFor(sourceID: sourceID, referenceID: referenceID)
            }
            return TranslationTokenBreakdown(
                sourceToken: token.sourceToken,
                normalizedToken: token.normalizedToken,
                diplomaticToken: token.diplomaticToken,
                glyphToken: glyphRenderer(token.diplomaticToken),
                resolutionStatus: TranslationResolutionStatus(rawValue: token.resolutionStatus) ?? .unavailable,
                provenance: tokenProvenance,
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
            supportLevel: (TranslationResolutionStatus(rawValue: template.resolutionStatus) ?? .unavailable) == .approximated
                ? .partial
                : .supported,
            evidenceTier: TranslationEvidenceTier(
                rawValue: template.attestationStatus == .attested ? TranslationEvidenceTier.attested.rawValue : TranslationEvidenceTier.reconstructed.rawValue,
            ) ?? .reconstructed,
            confidence: confidenceFor(
                status: TranslationResolutionStatus(rawValue: template.resolutionStatus) ?? .unavailable,
            ),
            notes: template.notes,
            unresolvedTokens: [],
            provenance: provenance,
            tokenBreakdown: breakdown,
            attestationRefs: template.referenceIDs,
            inputLanguage: request.sourceLanguage,
            engineVersion: engineVersion,
            datasetVersion: datasetVersion,
        )
    }
}

private struct TranslationTokenResolution {
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
        provenance: [TranslationProvenanceEntry] = [],
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

private struct MorphologyHints {
    let isPlural: Bool
    let isPast: Bool
    let isThirdPersonSingular: Bool
}

private struct MorphologyStageOutput {
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
                form: self.inflectVerb(entry: entry, hints: hints),
                notes: entry.paradigmID.map { ["Applied verb paradigm \($0)."] } ?? [],
            )
        case "noun":
            return MorphologyStageOutput(
                form: self.inflectNoun(entry: entry, hints: hints),
                notes: entry.paradigmID.map { ["Applied noun paradigm \($0)."] } ?? [],
            )
        case "preposition":
            return MorphologyStageOutput(form: entry.dativePhrase ?? entry.lemma, notes: [])
        default:
            return MorphologyStageOutput(form: entry.lemma, notes: [])
        }
    }

    private func inflectVerb(entry: OldNorseLexiconEntry, hints: MorphologyHints) -> String {
        let paradigm = entry.paradigmID.flatMap { self.lexiconLookup.paradigmTables().verbParadigms[$0] }
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
        let paradigm = entry.paradigmID.flatMap { self.lexiconLookup.paradigmTables().nounParadigms[$0] }
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

private struct PhonologyStageOutput {
    let form: String
    let notes: [String]
}

private struct YoungerFutharkPhonologyStage {
    func rewrite(_ text: String) -> PhonologyStageOutput {
        var current = text.lowercased()
        var notes: [String] = []

        current = self.applyRegexRule(
            value: current,
            pattern: #"[eéæ]"#,
            replacement: "i",
            notes: &notes,
            note: "Applied front-vowel reduction group.",
        )
        current = self.applyLiteralRule(
            value: current,
            target: "ja",
            replacement: "ia",
            notes: &notes,
            note: "Normalized glide-plus-vowel spelling for Younger Futhark.",
        )
        current = self.applyRegexRule(
            value: current,
            pattern: #"[oóǫøy]"#,
            replacement: "u",
            notes: &notes,
            note: "Applied rounded-vowel reduction group.",
        )
        current = self.applyLiteralRule(
            value: current,
            target: "ei",
            replacement: "i",
            notes: &notes,
            note: "Applied diphthong handling group.",
        )
        current = self.applyLiteralRule(
            value: current,
            target: "ey",
            replacement: "y",
            notes: &notes,
            note: "Applied diphthong handling group.",
        )
        current = self.applyLiteralRule(
            value: current,
            target: "g",
            replacement: "k",
            notes: &notes,
            note: "Applied voicing-neutralization group.",
        )
        current = self.applyLiteralRule(
            value: current,
            target: "d",
            replacement: "t",
            notes: &notes,
            note: "Applied devoicing group.",
        )
        current = self.applyLiteralRule(
            value: current,
            target: "ð",
            replacement: "þ",
            notes: &notes,
            note: "Normalized eth to thorn.",
        )
        for (target, replacement) in [("ll", "l"), ("nn", "n"), ("mm", "m"), ("rr", "r")] {
            current = self.applyLiteralRule(
                value: current,
                target: target,
                replacement: replacement,
                notes: &notes,
                note: "Applied geminate-simplification group.",
            )
        }

        return PhonologyStageOutput(form: current, notes: Array(Set(notes)))
    }

    private func applyRegexRule(
        value: String,
        pattern: String,
        replacement: String,
        notes: inout [String],
        note: String,
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
        note: String,
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
        "m": "ᛘ", "l": "ᛚ", " ": " ",
    ]

    private let shortTwigMap: [Character: Character] = [
        "f": "ᚠ", "u": "ᚢ", "v": "ᚢ", "w": "ᚢ", "þ": "ᚦ",
        "a": "ᛆ", "ą": "ᚭ", "r": "ᚱ", "ʀ": "ᛧ", "k": "ᚴ",
        "g": "ᚴ", "h": "ᚽ", "n": "ᚿ", "i": "ᛁ", "j": "ᛁ",
        "s": "ᛌ", "t": "ᛐ", "d": "ᛐ", "b": "ᛓ", "p": "ᛓ",
        "m": "ᛙ", "l": "ᛚ", " ": " ",
    ]

    func render(_ text: String, variant: YoungerFutharkVariant) -> String {
        let map = variant == .longBranch ? self.longBranchMap : self.shortTwigMap
        return String(text.map { map[$0] ?? $0 })
    }
}

private struct ProtoNorseStageOutput {
    let form: String?
    let notes: [String]
    let resolutionStatus: TranslationResolutionStatus
    let unresolvedToken: String?
    let provenance: [TranslationProvenanceEntry]
}

private struct ProtoNorseLexicalStage {
    let lexiconLookup: HistoricalLexiconLookup

    func reconstruct(
        token: ParsedEnglishToken,
        fidelity: TranslationFidelity,
        evidenceCap: TranslationEvidenceCap,
    ) -> ProtoNorseStageOutput {
        let entry = self.lexiconLookup.protoNorseFor(
            token.normalized,
            fidelity: fidelity,
            evidenceCap: evidenceCap,
        )
        let paraphrase = self.lexiconLookup.fallbackParaphrase(token.normalized)

        if let entry {
            return ProtoNorseStageOutput(
                form: entry.form,
                notes: [],
                resolutionStatus: entry.attestationStatus == .attested
                    ? .attested
                    : (entry.strictEligible ? .reconstructed : .approximated),
                unresolvedToken: nil,
                provenance: [self.lexiconLookup.provenanceFor(entry: entry)],
            )
        }

        if fidelity == .strict {
            return ProtoNorseStageOutput(
                form: nil,
                notes: ["Missing attested or reconstructed Elder Futhark pattern for '\(token.raw)'."],
                resolutionStatus: .unavailable,
                unresolvedToken: token.raw,
                provenance: [],
            )
        }

        if let paraphrase {
            return ProtoNorseStageOutput(
                form: paraphrase.lowercased(),
                notes: ["Used descriptive paraphrase for '\(token.raw)'."],
                resolutionStatus: .approximated,
                unresolvedToken: nil,
                provenance: [
                    self.lexiconLookup.provenanceFor(
                        sourceID: "internal_heuristics",
                        detail: "Readable-mode paraphrase",
                    ),
                ],
            )
        }

        if token.isProperNameCandidate {
            return ProtoNorseStageOutput(
                form: token.normalized,
                notes: ["Preserved an uncatalogued proper name phonetically."],
                resolutionStatus: .approximated,
                unresolvedToken: nil,
                provenance: [
                    self.lexiconLookup.provenanceFor(
                        sourceID: "internal_heuristics",
                        detail: "Proper-name preservation fallback",
                    ),
                ],
            )
        }

        return ProtoNorseStageOutput(
            form: token.normalized,
            notes: ["Used phonological preservation for '\(token.raw)'."],
            resolutionStatus: .approximated,
            unresolvedToken: nil,
            provenance: [
                self.lexiconLookup.provenanceFor(
                    sourceID: "internal_heuristics",
                    detail: "Proto-Norse preservation fallback",
                ),
            ],
        )
    }
}

private struct CirthOrthographyOutput {
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
        self.renderer = CirthFontRenderer(wordSeparator: ereborStore.ereborTables().wordSeparator)
    }

    func resolvePhrase(request: TranslationRequest) -> TranslationResult? {
        guard let mapping = ereborStore.ereborTables().phraseMappings.first(where: {
            $0.sourceText.normalizePhraseKey() == request.sourceText.normalizePhraseKey()
        }) else {
            return nil
        }

        let status = TranslationResolutionStatus(rawValue: mapping.resolutionStatus) ?? .unavailable
        if request.evidenceCap == .attestedOnly, status != .attested {
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
            glyphOutput: self.renderer.render(diplomatic: mapping.diplomaticForm),
            resolutionStatus: status,
            supportLevel: status == .approximated ? .partial : .supported,
            evidenceTier: TranslationResult.defaultEvidenceTier(for: status),
            confidence: confidenceFor(status: status),
            notes: mapping.notes,
            unresolvedTokens: [],
            provenance: mapping.referenceIDs.map {
                self.sourceCatalog.provenanceFor(
                    sourceID: "tolkien_appendix_e",
                    referenceID: $0,
                )
            },
            tokenBreakdown: [],
            attestationRefs: mapping.referenceIDs,
            inputLanguage: request.sourceLanguage,
            engineVersion: "cirth-phrase-v4",
            datasetVersion: self.ereborStore.datasetManifest().version,
        )
    }

    func renderToken(token: String, fidelity: TranslationFidelity) -> CirthOrthographyOutput {
        let tables = self.ereborStore.ereborTables()
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
                    provenance: [],
                )
            }

            diplomaticTokens.append(singleCharacter)
            remaining.removeFirst()
            approximated = true
        }

        let diplomatic = diplomaticTokens.joined(separator: tables.wordSeparator)
        return CirthOrthographyOutput(
            diplomatic: diplomatic,
            glyphs: self.renderer.render(diplomatic: diplomatic),
            notes: [
                appliedCanonicalRule ? "Applied Erebor sequence-table transcription." : nil,
                approximated ? "Used readable-mode character fallback for an unsupported Erebor sequence." : nil,
            ].compactMap { $0 },
            resolutionStatus: approximated ? .approximated : .reconstructed,
            unresolvedToken: nil,
            provenance: [
                self.sourceCatalog.provenanceFor(
                    sourceID: "tolkien_appendix_e",
                    detail: "Erebor orthography table",
                ),
            ],
        )
    }
}

private struct CirthFontRenderer {
    let wordSeparator: String

    func render(diplomatic: String) -> String {
        let normalized = diplomatic.replacingOccurrences(of: self.wordSeparator, with: "")
        return RunicTransliterator.transliterate(normalized, to: .cirth)
    }
}

private struct ElderRuneRenderer {
    func render(_ text: String) -> String {
        RunicTransliterator.transliterate(text, to: .elder)
    }
}

private struct TranslationEvidenceRequest {
    let script: RunicScript
    let derivationKind: TranslationDerivationKind
    let historicalStage: HistoricalStage
    let engineVersion: String
    let requestedVariant: String?
    let baseConfidence: Double
    let fallbackStatus: TranslationResolutionStatus
    let defaultNote: String
    let analysisWarnings: [String]
    let inputLanguage: TranslationSourceLanguage

    init(
        script: RunicScript,
        derivationKind: TranslationDerivationKind,
        historicalStage: HistoricalStage,
        engineVersion: String,
        requestedVariant: String? = nil,
        baseConfidence: Double,
        fallbackStatus: TranslationResolutionStatus,
        defaultNote: String,
        analysisWarnings: [String] = [],
        inputLanguage: TranslationSourceLanguage = .english,
    ) {
        self.script = script
        self.derivationKind = derivationKind
        self.historicalStage = historicalStage
        self.engineVersion = engineVersion
        self.requestedVariant = requestedVariant
        self.baseConfidence = baseConfidence
        self.fallbackStatus = fallbackStatus
        self.defaultNote = defaultNote
        self.analysisWarnings = analysisWarnings
        self.inputLanguage = inputLanguage
    }
}

private struct TranslationEvidenceSynthesizer {
    let datasetVersion: String

    func buildResult(
        request: TranslationRequest,
        resolutions: [TranslationTokenResolution],
        evidenceRequest: TranslationEvidenceRequest,
    ) -> TranslationResult {
        let unresolvedTokens = Array(Set(resolutions.compactMap(\.unresolvedToken)))
        let provenance = resolutions.flatMap(\.provenance).uniquedBy(\.stableID)
        let notes = Array(Set(resolutions.flatMap(\.notes)))
        let attestationRefs = provenance.compactMap(\.referenceID).uniqued()

        let resolutionStatus: TranslationResolutionStatus = if !unresolvedTokens.isEmpty {
            .unavailable
        } else if resolutions.contains(where: { $0.resolutionStatus == .approximated }) {
            .approximated
        } else {
            evidenceRequest.fallbackStatus
        }

        let available = resolutions.filter { $0.unresolvedToken == nil }
        let normalizedForm = resolutionStatus == .unavailable ? "" : stitchTokens(available.map(\.normalizedToken))
        let diplomaticForm = resolutionStatus == .unavailable ? "" : stitchTokens(available.map(\.diplomaticToken))
        let glyphOutput = resolutionStatus == .unavailable ? "" : stitchTokens(available.map(\.glyphToken))
        let userFacingWarnings = Array(Set(evidenceRequest.analysisWarnings))

        if request.fidelity == .strict,
           resolutionStatus != .unavailable,
           provenance.isEmpty
        {
            return TranslationResult(
                sourceText: request.sourceText,
                script: evidenceRequest.script,
                fidelity: request.fidelity,
                derivationKind: evidenceRequest.derivationKind,
                historicalStage: evidenceRequest.historicalStage,
                normalizedForm: "",
                diplomaticForm: "",
                glyphOutput: "",
                requestedVariant: evidenceRequest.requestedVariant,
                resolutionStatus: .unavailable,
                supportLevel: .unsupported,
                evidenceTier: .unsupported,
                confidence: 0,
                notes: ["Strict mode refused output because no provenance was available."],
                unresolvedTokens: unresolvedTokens.isEmpty ? [request.sourceText] : unresolvedTokens,
                provenance: [],
                tokenBreakdown: [],
                attestationRefs: [],
                inputLanguage: evidenceRequest.inputLanguage,
                userFacingWarnings: userFacingWarnings + ["Strict mode requires cited evidence for visible output."],
                engineVersion: evidenceRequest.engineVersion,
                datasetVersion: self.datasetVersion,
            )
        }

        let evidenceTier = TranslationResult.defaultEvidenceTier(for: resolutionStatus)
        let supportLevel: TranslationSupportLevel = if resolutionStatus == .unavailable {
            .unsupported
        } else if evidenceTier == .approximate || !userFacingWarnings.isEmpty {
            .partial
        } else {
            .supported
        }

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
            supportLevel: supportLevel,
            evidenceTier: evidenceTier,
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
                    provenance: $0.provenance,
                )
            },
            attestationRefs: attestationRefs,
            inputLanguage: evidenceRequest.inputLanguage,
            userFacingWarnings: userFacingWarnings,
            engineVersion: evidenceRequest.engineVersion,
            datasetVersion: self.datasetVersion,
        )
    }
}

// MARK: - Utilities

private extension ParsedEnglishToken {
    func asPunctuationResolution() -> TranslationTokenResolution {
        TranslationTokenResolution(
            sourceToken: self.raw,
            normalizedToken: self.raw,
            diplomaticToken: self.raw,
            glyphToken: self.raw,
            resolutionStatus: .reconstructed,
        )
    }

    func toMorphologyHints() -> MorphologyHints {
        let raw = self.rawLowercased
        return MorphologyHints(
            isPlural: raw.hasSuffix("s") && !raw.hasSuffix("'s"),
            isPast: raw.hasSuffix("ed"),
            isThirdPersonSingular: raw.hasSuffix("s") && !raw.hasSuffix("ss"),
        )
    }
}

private extension Array {
    func safeSlice(from startIndex: Int, to endExclusive: Int) -> [Element] {
        guard !isEmpty, startIndex < count, startIndex < endExclusive else { return [] }
        return Array(self[Swift.max(0, startIndex) ..< Swift.min(count, endExclusive)])
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
            supportLevel: supportLevel,
            evidenceTier: evidenceTier,
            confidence: confidence,
            notes: notes,
            unresolvedTokens: unresolvedTokens,
            provenance: provenance,
            tokenBreakdown: tokenBreakdown,
            attestationRefs: attestationRefs,
            inputLanguage: inputLanguage,
            userFacingWarnings: userFacingWarnings,
            engineVersion: engineVersion,
            datasetVersion: datasetVersion,
            createdAt: createdAt,
            updatedAt: updatedAt,
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
            supportLevel: supportLevel,
            evidenceTier: evidenceTier,
            confidence: confidence,
            notes: notes,
            unresolvedTokens: unresolvedTokens,
            provenance: provenance,
            tokenBreakdown: tokenBreakdown,
            attestationRefs: attestationRefs,
            inputLanguage: inputLanguage,
            userFacingWarnings: userFacingWarnings,
            engineVersion: engineVersion,
            datasetVersion: datasetVersion,
            createdAt: createdAt,
            updatedAt: Date(),
        )
    }
}

private extension [TranslationProvenanceEntry] {
    func uniquedBy<T: Hashable>(_ keyPath: KeyPath<Element, T>) -> [Element] {
        var seen = Set<T>()
        return filter { seen.insert($0[keyPath: keyPath]).inserted }
    }
}

private extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}

private func confidenceFor(
    status: TranslationResolutionStatus,
    baseConfidence: Double = 0.9,
) -> Double {
    switch status {
    case .attested:
        0.98
    case .reconstructed:
        baseConfidence
    case .approximated:
        max(baseConfidence - 0.18, 0.3)
    case .unavailable:
        0
    }
}

private func youngerBaseConfidence(for fidelity: TranslationFidelity) -> Double {
    switch fidelity {
    case .strict:
        0.9
    case .readable:
        0.82
    case .decorative:
        0.7
    }
}

private func elderBaseConfidence(for fidelity: TranslationFidelity) -> Double {
    switch fidelity {
    case .strict:
        0.84
    case .readable:
        0.74
    case .decorative:
        0.6
    }
}

private func cirthBaseConfidence(for fidelity: TranslationFidelity) -> Double {
    switch fidelity {
    case .strict:
        0.72
    case .readable:
        0.6
    case .decorative:
        0.54
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
