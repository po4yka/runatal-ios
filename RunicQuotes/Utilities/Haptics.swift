//
//  Haptics.swift
//  RunicQuotes
//
//  Created by Claude on 13.02.26.
//

import Foundation
#if canImport(UIKit)
    import UIKit
#endif

/// Importance tiers for app haptics.
enum HapticTier {
    case scriptSwitch
    case newQuote
    case saveOrShare
}

/// Centralized haptic feedback dispatcher.
@MainActor
enum Haptics {
    static func trigger(_ tier: HapticTier) {
        #if canImport(UIKit)
            switch tier {
            case .scriptSwitch:
                let generator = UISelectionFeedbackGenerator()
                generator.selectionChanged()
            case .newQuote:
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
            case .saveOrShare:
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }
        #endif
    }
}
