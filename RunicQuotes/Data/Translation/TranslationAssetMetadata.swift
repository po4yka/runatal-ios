//
//  TranslationAssetMetadata.swift
//  RunicQuotes
//
//  Created by Claude on 09.10.26.
//

import Foundation

struct TranslationAssetMetadata: Codable, Sendable {
    let id: String
    let sourceID: String
    let sourceWork: String
    let citations: [String]
    let historicalStage: HistoricalStage
    let inventory: TranslationInventoryKind
    let licenseNote: String

    private enum CodingKeys: String, CodingKey {
        case id, sourceWork, citations, historicalStage, inventory, licenseNote
        case sourceID = "sourceId"
    }
}

extension KeyedDecodingContainer {
    func decodeRaw<Value: RawRepresentable>(_ type: Value.Type, forKey key: Key) throws -> String where Value.RawValue == String {
        let raw = try self.decode(String.self, forKey: key)
        guard Value(rawValue: raw) != nil else {
            throw DecodingError.dataCorruptedError(forKey: key, in: self, debugDescription: "Unknown enum value: \(raw)")
        }
        return raw
    }

    func decodeScript(forKey key: Key) throws -> String {
        let raw = try self.decode(String.self, forKey: key)
        guard RunicScript.allCases.contains(where: { $0.translationScriptName == raw }) else {
            throw DecodingError.dataCorruptedError(forKey: key, in: self, debugDescription: "Unknown translation script")
        }
        return raw
    }

    func decodeRequestedVariant(forKey key: Key, script: String) throws -> String? {
        let raw = try self.decodeIfPresent(String.self, forKey: key)
        if script == RunicScript.younger.translationScriptName, let raw, YoungerFutharkVariant(rawValue: raw) == nil {
            throw DecodingError.dataCorruptedError(forKey: key, in: self, debugDescription: "Unknown Younger Futhark variant")
        }
        return raw
    }

    func decodeConfidence(forKey key: Key) throws -> Double {
        let confidence = try self.decode(Double.self, forKey: key)
        guard confidence.isFinite, (0 ... 1).contains(confidence) else {
            throw DecodingError.dataCorruptedError(forKey: key, in: self, debugDescription: "Confidence must be between zero and one")
        }
        return confidence
    }
}
