//
//  OldNorseSentenceGrammar.swift
//  RunicQuotes
//
//  Created by Claude on 09.10.26.
//

import Foundation

/// A lexical analysis input retaining the source occurrence position.
struct OldNorseGrammarToken {
    let raw: String
    let normalized: String
    let entry: OldNorseLexiconEntry?
    let isWord: Bool
}

struct OldNorseGrammaticalForm {
    let form: String
    let sourceID: String
    let citations: [String]
}

struct OldNorseGrammarPlan {
    var forms: [Int: OldNorseGrammaticalForm] = [:]
    var warnings: [String] = []

    var isSupported: Bool {
        self.warnings.isEmpty
    }
}

/// Bounded, source-backed morphology for a single subject–verb clause and noun
/// phrases. No guessed English suffixes manufacture an Old Norse paradigm.
struct OldNorseSentenceGrammar {
    let rules: GrammarRulesData

    private struct Agreement {
        let person: Int
        let number: String
        let gender: String?
        var verbKey: String {
            "\(self.person)_\(self.number)"
        }
    }

    func analyze(_ tokens: [OldNorseGrammarToken]) -> OldNorseGrammarPlan {
        var plan = OldNorseGrammarPlan()
        let words = tokens.indices.filter { tokens[$0].isWord }
        guard let firstWord = words.first, let lastWord = words.last else { return plan }
        if tokens.indices.contains(where: { $0 > firstWord && $0 < lastWord && !tokens[$0].isWord }) {
            plan.warnings.append("Internal punctuation or literal symbols separate unsupported sentence constructions; output is a lexical approximation.")
            return plan
        }
        let verbs = words.filter { tokens[$0].entry?.partOfSpeech == "verb" }
        guard verbs.count <= 1 else {
            plan.warnings = ["Multiple clauses and auxiliary constructions are outside the supported grammar; output is a lexical approximation."]
            return plan
        }
        guard let verb = verbs.first else {
            if words.count == 1, tokens[words[0]].entry?.partOfSpeech != "noun" {
                return plan
            }
            _ = self.nounPhrase(words, grammaticalCase: "NOMINATIVE", tokens: tokens, plan: &plan)
            return plan
        }
        let subjectWords = words.filter { $0 < verb }
        guard !subjectWords.isEmpty else {
            if words.count != 1 {
                plan.warnings.append("Imperatives and omitted subjects are outside the supported sentence grammar.")
            }
            return plan
        }
        let agreement: Agreement? = if subjectWords.count == 1, let feature = self.rules.pronounFeatures[tokens[subjectWords[0]].normalized] {
            Agreement(person: feature.person, number: feature.number, gender: feature.gender)
        } else {
            self.nounPhrase(subjectWords, grammaticalCase: "NOMINATIVE", tokens: tokens, plan: &plan)
        }
        guard let agreement, let entry = tokens[verb].entry else { return plan }
        let rawVerb = tokens[verb].raw.lowercased()
        let sourceForm = entry.englishVerbForms?[rawVerb]
        let finiteForm = (sourceForm?.tense == "PAST" ? entry.pastForms : entry.presentForms)?[agreement.verbKey]
        if let sourceForm, sourceForm.agreements.contains(agreement.verbKey), let form = finiteForm {
            plan.forms[verb] = self.form(form, entry: entry)
        } else {
            plan.warnings.append("No cited finite verb form matches the subject person, number, and English tense.")
        }
        let tail = words.filter { $0 > verb }
        self.resolveTail(tail, verb: entry, agreement: agreement, tokens: tokens, plan: &plan)
        return plan
    }

    private func resolveTail(
        _ words: [Int],
        verb: OldNorseLexiconEntry,
        agreement: Agreement,
        tokens: [OldNorseGrammarToken],
        plan: inout OldNorseGrammarPlan,
    ) {
        let preposition = words.firstIndex { self.rules.governedPrepositions[tokens[$0].normalized] != nil }
        let object = preposition.map { Array(words.prefix($0)) } ?? words
        if object.isEmpty, verb.requiresObject == true {
            plan.warnings.append("This possessive construction requires an explicit accusative object.")
        }
        if !object.isEmpty {
            let adjective = object.count == 1 ? tokens[object[0]].entry : nil
            let adjectiveKey = "NOMINATIVE_\(agreement.number)_\(agreement.gender ?? "UNSPECIFIED")"
            if verb.english == "be", let adjective, adjective.partOfSpeech == "adjective", let form = adjective.adjectiveForms?[adjectiveKey] {
                plan.forms[object[0]] = self.form(form, entry: adjective)
            } else if verb.english == "be", adjective?.partOfSpeech == "adjective" {
                plan.warnings.append("Predicate adjective agreement requires a supported subject gender reading.")
            } else if let grammaticalCase = verb.objectCase ?? (verb.english == "be" ? "NOMINATIVE" : nil) {
                _ = self.nounPhrase(object, grammaticalCase: grammaticalCase, tokens: tokens, plan: &plan)
            } else {
                plan.warnings.append("This lexical verb has no cited object-case construction in the supported inventory.")
            }
        }
        guard let preposition else { return }
        let prepositionIndex = words[preposition]
        guard let government = self.rules.governedPrepositions[tokens[prepositionIndex].normalized] else { return }
        let nounWords = Array(words.dropFirst(preposition + 1))
        if nounWords.contains(where: { self.rules.prepositionMap[tokens[$0].normalized] != nil }) {
            plan.warnings.append("Nested preposition phrases are outside the supported grammar.")
            return
        }
        plan.forms[prepositionIndex] = OldNorseGrammaticalForm(form: government.lemma, sourceID: government.sourceID, citations: government.citations)
        _ = self.nounPhrase(nounWords, grammaticalCase: government.grammaticalCase, tokens: tokens, plan: &plan)
    }

    private func nounPhrase(
        _ words: [Int], grammaticalCase: String, tokens: [OldNorseGrammarToken], plan: inout OldNorseGrammarPlan,
    ) -> Agreement? {
        let content = words.filter { !self.rules.removableWords.contains(tokens[$0].normalized) }
        guard let head = content.last, let noun = tokens[head].entry, noun.partOfSpeech == "noun",
              content.dropLast().allSatisfy({ tokens[$0].entry?.partOfSpeech == "adjective" })
        else {
            plan.warnings.append("The noun phrase is outside the cited adjective–noun grammar.")
            return nil
        }
        let number = noun.englishPluralForms?.contains(tokens[head].raw.lowercased()) == true ? "PLURAL" : "SINGULAR"
        let definite = words.contains { tokens[$0].normalized == "the" }
        let key = "\(definite ? "DEFINITE_" : "")\(grammaticalCase)_\(number)"
        guard let nounForm = noun.nounForms?[key], let gender = noun.gender else {
            plan.warnings.append("No cited noun form supports the requested case, number, and definiteness.")
            return nil
        }
        plan.forms[head] = self.form(nounForm, entry: noun)
        for index in content.dropLast() {
            guard !definite, let adjective = tokens[index].entry,
                  let adjectiveForm = adjective.adjectiveForms?["\(grammaticalCase)_\(number)_\(gender)"]
            else {
                plan.warnings.append("No cited adjective form supports this noun's case, gender, number, and definiteness.")
                continue
            }
            plan.forms[index] = self.form(adjectiveForm, entry: adjective)
        }
        return Agreement(person: 3, number: number, gender: gender)
    }

    private func form(_ form: String, entry: OldNorseLexiconEntry) -> OldNorseGrammaticalForm {
        OldNorseGrammaticalForm(
            form: form,
            sourceID: entry.inflectionSourceID ?? entry.sourceID,
            citations: entry.inflectionCitations ?? entry.citations,
        )
    }
}
