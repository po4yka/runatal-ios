//
//  CirthMap.swift
//  RunicQuotes
//
//  Created by Claude on 30.09.25.
//

import Foundation

/// Spelling transcription in Angerthas Erebor mode, sharing verified numbered
/// graph identities with the reference catalog. This is not English phoneme analysis.
let cirthMap: [Character: String] = {
    var mapping = Dictionary(uniqueKeysWithValues: CirthGraph.erebor.filter { $0.spelling.count == 1 }.map { (Character($0.spelling), $0.glyph) })
    mapping["c"] = mapping["k"]
    mapping["q"] = mapping["k"]
    return mapping
}()

let cirthDigraphs: [String: String] = {
    var mapping = Dictionary(uniqueKeysWithValues: CirthGraph.erebor.filter { $0.spelling.count > 1 }.map { ($0.spelling, $0.glyph) })
    mapping["ph"] = cirthMap["f"]
    return mapping
}()
