//
//  TranslationDatasetValidation.swift
//  RunicQuotes
//
//  Created by Claude on 09.10.26.
//

import Foundation

enum TranslationDatasetError: LocalizedError {
    case missingResource(String)
    case invalidMetadata(String)

    var errorDescription: String? {
        switch self {
        case .missingResource(let name): "Missing translation asset: \(name)"
        case .invalidMetadata(let detail): "Invalid translation metadata: \(detail)"
        }
    }
}

extension AssetTranslationDatasetProvider {
    func validateReferences() throws {
        let sourceIDs = try self.validateSources()
        let referenceIDs = try self.validateCorpusReferences(sources: sourceIDs)
        try self.validateLexicons(sources: sourceIDs)
        try self.validateTemplates(references: referenceIDs)
        try self.validateGold(sources: sourceIDs, references: referenceIDs)
        try self.validateRuleMetadata(sources: sourceIDs, references: referenceIDs)
    }

    private func validateSources() throws -> Set<String> {
        let sources = self.sourceManifest().sources
        try self.requireUnique(sources.map(\.id))
        for source in sources {
            guard !source.name.isEmpty, !source.role.isEmpty, !(source.work ?? "").isEmpty,
                  !source.license.isEmpty, !(source.licenseNote ?? "").isEmpty, self.validURL(source.url)
            else {
                throw TranslationDatasetError.invalidMetadata("Source attribution is incomplete")
            }
        }
        return Set(sources.map(\.id))
    }

    private func validateCorpusReferences(sources sourceIDs: Set<String>) throws -> Set<String> {
        let references = self.runicCorpusReferences()
        try self.requireUnique(references.map(\.id))
        for reference in references {
            guard sourceIDs.contains(reference.sourceID), !reference.label.isEmpty,
                  self.validURL(reference.url ?? "")
            else {
                throw TranslationDatasetError.invalidMetadata("Unknown or incomplete corpus reference")
            }
        }
        return Set(references.map(\.id))
    }

    private func validateLexicons(sources sourceIDs: Set<String>) throws {
        try self.requireUnique(self.oldNorseLexicon().map(\.id))
        try self.requireUnique(self.protoNorseLexicon().map(\.id))
        for entry in self.oldNorseLexicon() {
            try self.validateInflection(entry)
            guard !entry.english.isEmpty, !entry.lemma.isEmpty else { throw TranslationDatasetError.invalidMetadata("Empty lexical form") }
            try self.validateLexical(
                sourceID: entry.sourceID,
                citations: entry.citations,
                strict: entry.strictEligible,
                inventory: entry.inventory,
                sources: sourceIDs,
            )
            if let source = entry.inflectionSourceID, !sourceIDs.contains(source) {
                throw TranslationDatasetError.invalidMetadata("Unknown inflection source")
            }
        }
        for entry in self.protoNorseLexicon() {
            guard !entry.english.isEmpty, !entry.form.isEmpty else { throw TranslationDatasetError.invalidMetadata("Empty lexical form") }
            try self.validateLexical(
                sourceID: entry.sourceID,
                citations: entry.citations,
                strict: entry.strictEligible,
                inventory: entry.inventory,
                sources: sourceIDs,
            )
        }
    }

    private func validateTemplates(references referenceIDs: Set<String>) throws {
        let templates = self.youngerPhraseTemplates() + self.elderAttestedForms()
        try self.requireUnique(templates.map(\.id))
        for template in templates {
            try self.requireReferences(template.referenceIDs, known: referenceIDs)
            for token in template.tokenBreakdown {
                try self.requireReferences(token.referenceIDs, known: referenceIDs)
            }
        }
    }

    private func validateGold(sources sourceIDs: Set<String>, references referenceIDs: Set<String>) throws {
        try self.requireUnique(self.goldExamples().map(\.id))
        for example in self.goldExamples() {
            guard !example.results.isEmpty, !(example.regressionID ?? "").isEmpty else { throw TranslationDatasetError.invalidMetadata("Empty gold example") }
            for result in example.results {
                try self.requireReferences(result.attestationRefs, known: referenceIDs)
                for provenance in result.provenance + result.tokenBreakdown.flatMap(\.provenance) {
                    guard sourceIDs.contains(provenance.sourceID) else { throw TranslationDatasetError.invalidMetadata("Unknown provenance source") }
                    if let reference = provenance.referenceID {
                        try self.requireReferences([reference], known: referenceIDs)
                    }
                }
            }
        }
        try self.requireUnique(self.goldCorpus().benchmarks.map(\.id))
        for benchmark in self.goldCorpus().benchmarks {
            guard !benchmark.expectations.isEmpty else { throw TranslationDatasetError.invalidMetadata("Empty benchmark") }
            for expectation in benchmark.expectations {
                try self.requireReferences(expectation.attestationRefs, known: referenceIDs)
            }
        }
    }

    private func validateRuleMetadata(sources sourceIDs: Set<String>, references referenceIDs: Set<String>) throws {
        let metadata = [
            self.grammarRules().metadata,
            self.paradigmTables().metadata,
            self.ereborTables().metadata,
            self.nameAdaptations().metadata,
            self.fallbackTemplates().metadata,
        ]
        for item in metadata {
            guard !item.id.isEmpty, sourceIDs.contains(item.sourceID), !item.sourceWork.isEmpty,
                  !item.citations.isEmpty, !item.licenseNote.isEmpty
            else {
                throw TranslationDatasetError.invalidMetadata("Rule inventory lacks source metadata")
            }
        }
        for phrase in self.ereborTables().phraseMappings {
            try self.requireReferences(phrase.referenceIDs, known: referenceIDs)
        }
        let manifest = self.datasetManifest()
        guard !manifest.version.isEmpty, !manifest.generatedBy.isEmpty,
              manifest.generatedAt.range(of: #"^\d{4}-\d{2}-\d{2}$"#, options: .regularExpression) != nil,
              !(manifest.sourceOfTruthPackage ?? "").isEmpty
        else {
            throw TranslationDatasetError.invalidMetadata("Dataset manifest is incomplete")
        }
    }

    private func validateInflection(_ entry: OldNorseLexiconEntry) throws {
        let cases = ["NOMINATIVE", "ACCUSATIVE", "GENITIVE", "DATIVE"]
        let numbers = ["SINGULAR", "PLURAL"]
        let genders = ["MASCULINE", "FEMININE", "NEUTER"]
        let agreements = Set((1 ... 3).flatMap { person in numbers.map { "\(person)_\($0)" } })
        let nounKeys = Set(cases.flatMap { grammaticalCase in numbers.flatMap { ["\(grammaticalCase)_\($0)", "DEFINITE_\(grammaticalCase)_\($0)"] } })
        let adjectiveKeys = Set(cases.flatMap { grammaticalCase in numbers.flatMap { number in genders.map { "\(grammaticalCase)_\(number)_\($0)" } } })
        let validForms = [
            entry.nounForms?.keys.allSatisfy(nounKeys.contains) ?? true,
            entry.adjectiveForms?.keys.allSatisfy(adjectiveKeys.contains) ?? true,
            entry.presentForms?.keys.allSatisfy(agreements.contains) ?? true,
            entry.pastForms?.keys.allSatisfy(agreements.contains) ?? true,
        ]
        guard validForms.allSatisfy({ $0 }) else {
            throw TranslationDatasetError.invalidMetadata("Unknown inflection key")
        }
        let forms = [entry.nounForms, entry.adjectiveForms, entry.presentForms, entry.pastForms].compactMap { $0 }.flatMap(\.values)
        if !forms.isEmpty {
            guard forms.allSatisfy({ !$0.isEmpty }), entry.inflectionSourceID != nil,
                  !(entry.inflectionCitations ?? []).isEmpty else { throw TranslationDatasetError.invalidMetadata("Uncited or empty inflection forms") }
        }
        if let grammaticalCase = entry.objectCase, !cases.contains(grammaticalCase) {
            throw TranslationDatasetError.invalidMetadata("Unknown governed object case")
        }
        for form in entry.englishVerbForms?.values ?? [String: EnglishVerbForm]().values {
            guard ["PRESENT", "PAST"].contains(form.tense), !form.agreements.isEmpty,
                  form.agreements.allSatisfy(agreements.contains) else { throw TranslationDatasetError.invalidMetadata("Unknown finite-verb features") }
        }
    }

    private func validateLexical(
        sourceID: String,
        citations: [String],
        strict: Bool,
        inventory: TranslationInventoryKind,
        sources: Set<String>,
    ) throws {
        guard sources.contains(sourceID), !citations.isEmpty, !strict || inventory.isStrictEligible else {
            throw TranslationDatasetError.invalidMetadata("Lexical evidence is incomplete or ineligible")
        }
    }

    private func requireUnique(_ ids: [String]) throws {
        guard ids.allSatisfy({ !$0.isEmpty }), Set(ids).count == ids.count else {
            throw TranslationDatasetError.invalidMetadata("Duplicate or empty stable identifiers")
        }
    }

    private func requireReferences(_ ids: [String], known: Set<String>) throws {
        guard ids.allSatisfy(known.contains) else { throw TranslationDatasetError.invalidMetadata("Dangling corpus reference") }
    }

    private func validURL(_ raw: String) -> Bool {
        guard let url = URL(string: raw) else { return false }
        return url.scheme == "https" && url.host != nil
    }
}
