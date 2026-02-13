//
//  Haptics.swift
//  RunicQuotes
//
//  Created by Codex on 2026-02-13.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Importance tiers for app haptics.
enum HapticTier: Sendable {
    case scriptSwitch
    case newQuote
    case saveOrShare
}

/// Centralized haptic feedback dispatcher.
enum Haptics {
    static func trigger(_ tier: HapticTier) {
#if canImport(UIKit)
        Task { @MainActor in
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
        }
#endif
    }
}
