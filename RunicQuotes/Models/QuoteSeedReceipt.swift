//
//  QuoteSeedReceipt.swift
//  RunicQuotes
//
//  Created by Claude on 09.10.26.
//

import CryptoKit
import Foundation
import SwiftData

/// Import identity retained after erasure so a catalog update cannot resurrect a removed quote.
@Model
final class QuoteSeedReceipt {
    @Attribute(.unique) var seedID: String
    var quoteID: UUID?

    init(seedID: String, quoteID: UUID?) {
        self.seedID = seedID
        self.quoteID = quoteID
    }

    static func stableQuoteID(for seedID: String) -> UUID {
        let bytes = Array(SHA256.hash(data: Data("runatal:builtin:\(seedID)".utf8)).prefix(16))
        return UUID(uuid: (
            bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5], bytes[6], bytes[7],
            bytes[8], bytes[9], bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15],
        ))
    }
}
