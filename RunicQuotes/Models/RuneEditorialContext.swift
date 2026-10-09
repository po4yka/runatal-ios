//
//  RuneEditorialContext.swift
//  RunicQuotes
//
//  Created by Claude on 09.10.26.
//

import Foundation

enum RuneNameEvidence: String, Codable, CaseIterable, Identifiable, Sendable {
    case comparativeReconstruction
    case medievalPoemTradition
    case fictionalScript

    var id: String {
        self.rawValue
    }

    var displayName: String {
        switch self {
        case .comparativeReconstruction: "Comparative reconstruction"
        case .medievalPoemTradition: "Medieval rune-poem tradition"
        case .fictionalScript: "Tolkien's fictional script"
        }
    }
}

struct RuneReferenceSource: Identifiable, Sendable {
    let title: String
    let url: String
    var id: String {
        self.url
    }
}

extension RuneInfo {
    var nameEvidence: RuneNameEvidence {
        switch self.script {
        case .elder: .comparativeReconstruction
        case .younger: .medievalPoemTradition
        case .cirth: .fictionalScript
        }
    }

    var historicalNote: String {
        switch self.script {
        case .elder:
            let caution = Self.meaningCautions[self.id] ?? "Later rune poems provide comparative name and meaning evidence."
            return "The Elder name is a conventional reconstruction, not a name recorded beside this glyph in an Elder inscription. \(caution)"
        case .younger:
            return "The name and gloss belong to medieval Scandinavian rune-poem traditions; meanings can differ between Norwegian and Icelandic texts. They are not evidence for a universal ancient divination system."
        case .cirth:
            let note = CirthGraph.erebor.first { $0.id == self.id }?.modeNote ?? "Numbered graph in Angerthas Erebor mode."
            return "This is a graph in Tolkien's fictional script. \(note) CSUR is a proposed private-use encoding and requires a compatible font."
        }
    }

    var referenceSources: [RuneReferenceSource] {
        switch self.script {
        case .elder, .younger:
            [
                RuneReferenceSource(title: "Unicode Runic chart (glyph identity)", url: "https://www.unicode.org/charts/PDF/U16A0.pdf"),
                RuneReferenceSource(title: "Rune poems (later comparative texts)", url: "https://en.wikisource.org/wiki/Rune_poems"),
            ]
        case .cirth:
            [
                RuneReferenceSource(title: "Appendix E table and Erebor mode notes", url: "https://mirrors.mit.edu/CTAN/fonts/cirth/cirth.pdf"),
                RuneReferenceSource(title: "CSUR proposed graph encoding", url: "https://www.evertype.com/standards/csur/cirth.html"),
            ]
        }
    }

    /// Project-authored contemporary prompts, explicitly separate from historical evidence.
    var modernReflection: String? {
        Self.reflections[self.id]
    }

    private static let meaningCautions: [String: String] = [
        "elder-kenaz": "Old English cen concerns a torch, while Scandinavian kaun concerns an ulcer; the reconstructed name and meaning are disputed.",
        "elder-perthro": "The name's meaning is uncertain; 'lot cup' is an interpretation rather than an established translation.",
        "elder-algiz": "The later Old English elk-sedge name does not establish an Elder meaning of protection.",
        "elder-eihwaz": "The yew comparison uses later names; the phonetic value is disputed and is often conventionally transcribed ï.",
        "elder-thurisaz": "Scandinavian poems name a giant, while Old English uses the thorn name; these are different later traditions.",
    ]

    private static let reflections: [String: String] = [
        "elder-fehu": "Consider what you can share with others.",
        "elder-uruz": "Reflect on the strength you bring to a difficult task.",
        "elder-thurisaz": "Consider where you need a clear boundary.",
        "elder-ansuz": "Choose words that help another person understand you.",
        "elder-raidho": "Reflect on the direction of your next step.",
        "elder-kenaz": "Consider what you would like to learn or make.",
        "elder-gebo": "Think about the balance of giving and receiving.",
        "elder-wunjo": "Notice a source of joy in ordinary life.",
        "elder-hagalaz": "Consider how you respond when a plan changes.",
        "elder-naudiz": "Reflect on what a constraint teaches you.",
        "elder-isa": "Allow time to pause before acting.",
        "elder-jera": "Notice how steady effort accumulates over time.",
        "elder-eihwaz": "Reflect on what helps you endure uncertainty.",
        "elder-perthro": "Consider how you meet an unknown outcome.",
        "elder-algiz": "Think about what care and protection mean today.",
        "elder-sowilo": "Notice what gives you clarity and energy.",
        "elder-tiwaz": "Reflect on the responsibilities you choose to accept.",
        "elder-berkano": "Consider something you would like to nurture.",
        "elder-ehwaz": "Think about a partnership that deserves your care.",
        "elder-mannaz": "Notice what you learn through other people.",
        "elder-laguz": "Reflect on what you can adapt to.",
        "elder-ingwaz": "Give an unfinished idea time to develop.",
        "elder-dagaz": "Notice an opportunity to see something differently.",
        "elder-othala": "Consider which inherited practices you choose to continue.",
    ]
}
