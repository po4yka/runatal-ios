//
//  RunicTips.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import SwiftUI
import TipKit

enum FeatureDiscoveryState {
    @Parameter static var hasCompletedOnboarding: Bool = false
    @Parameter static var homeQuoteReady: Bool = false
}

enum FeatureDiscoveryEvents {
    static let homeAdvancedQuote = Tips.Event(id: "feature-discovery.home.advanced-quote")
    static let homeSavedQuote = Tips.Event(id: "feature-discovery.home.saved-quote")
    static let collectionsSelectedCollection = Tips.Event(id: "feature-discovery.collections.selected-collection")
    static let searchSelectedCollectionFilter = Tips.Event(id: "feature-discovery.search.selected-filter")
    static let translationAdjustedMethod = Tips.Event(id: "feature-discovery.translation.adjusted-method")
    static let settingsAppliedPreset = Tips.Event(id: "feature-discovery.settings.applied-preset")
    static let settingsAdjustedWidget = Tips.Event(id: "feature-discovery.settings.adjusted-widget")
}

struct HomeNextQuoteTip: Tip {
    var title: Text {
        Text("Cycle the reading")
    }

    var message: Text? {
        Text("Tap New Quote to pull another passage into the current script.")
    }

    var image: Image? {
        Image(systemName: "sparkles")
    }

    var rules: [Rule] {
        #Rule(FeatureDiscoveryState.$hasCompletedOnboarding) { hasCompletedOnboarding in
            hasCompletedOnboarding
        }

        #Rule(FeatureDiscoveryEvents.homeAdvancedQuote) {
            $0.donations.count == 0
        }
    }

    var options: [any TipOption] {
        Tips.IgnoresDisplayFrequency(true)
        Tips.MaxDisplayCount(1)
    }
}

struct HomeSaveQuoteTip: Tip {
    var title: Text {
        Text("Keep the lines that matter")
    }

    var message: Text? {
        Text("Save a passage to revisit it later in your personal library.")
    }

    var image: Image? {
        Image(systemName: "bookmark")
    }

    var rules: [Rule] {
        #Rule(FeatureDiscoveryState.$hasCompletedOnboarding) { hasCompletedOnboarding in
            hasCompletedOnboarding
        }

        #Rule(FeatureDiscoveryEvents.homeAdvancedQuote) {
            $0.donations.count > 0
        }

        #Rule(FeatureDiscoveryEvents.homeSavedQuote) {
            $0.donations.count == 0
        }
    }

    var options: [any TipOption] {
        Tips.IgnoresDisplayFrequency(true)
        Tips.MaxDisplayCount(1)
    }
}

struct CollectionsHomeStreamTip: Tip {
    var title: Text {
        Text("Collections steer Home")
    }

    var message: Text? {
        Text("Pick any shelf here and the Home tab will continue reading from that collection.")
    }

    var image: Image? {
        Image(systemName: "square.grid.2x2")
    }

    var rules: [Rule] {
        #Rule(FeatureDiscoveryEvents.collectionsSelectedCollection) {
            $0.donations.count == 0
        }
    }

    var options: [any TipOption] {
        Tips.MaxDisplayCount(1)
    }
}

struct SearchCollectionFilterTip: Tip {
    var title: Text {
        Text("Narrow results with a chip")
    }

    var message: Text? {
        Text("Once a search lands, use a collection chip to tighten the results without rewriting the query.")
    }

    var image: Image? {
        Image(systemName: "line.3.horizontal.decrease.circle")
    }

    var rules: [Rule] {
        #Rule(FeatureDiscoveryEvents.searchSelectedCollectionFilter) {
            $0.donations.count == 0
        }
    }

    var options: [any TipOption] {
        Tips.MaxDisplayCount(1)
    }
}

struct TranslationMethodTip: Tip {
    var title: Text {
        Text("Use the right translation path")
    }

    var message: Text? {
        Text("Direct keeps the original wording intact. Translate trades fidelity for historically grounded rendering.")
    }

    var image: Image? {
        Image(systemName: "character.cursor.ibeam")
    }

    var rules: [Rule] {
        #Rule(FeatureDiscoveryEvents.translationAdjustedMethod) {
            $0.donations.count == 0
        }
    }

    var options: [any TipOption] {
        Tips.MaxDisplayCount(1)
    }
}

struct SettingsTypographyPresetTip: Tip {
    var title: Text {
        Text("Try a curated pairing")
    }

    var message: Text? {
        Text("Recommended combinations switch script and font together, so you can sample a full reading mood in one tap.")
    }

    var image: Image? {
        Image(systemName: "textformat.alt")
    }

    var rules: [Rule] {
        #Rule(FeatureDiscoveryEvents.settingsAppliedPreset) {
            $0.donations.count == 0
        }
    }

    var options: [any TipOption] {
        Tips.MaxDisplayCount(1)
    }
}

struct SettingsWidgetConfigurationTip: Tip {
    var title: Text {
        Text("Tune the widget once")
    }

    var message: Text? {
        Text("These controls shape how your widget reads at a glance, without affecting the main reading screen.")
    }

    var image: Image? {
        Image(systemName: "rectangle.on.rectangle")
    }

    var rules: [Rule] {
        #Rule(FeatureDiscoveryEvents.settingsAppliedPreset) {
            $0.donations.count > 0
        }

        #Rule(FeatureDiscoveryEvents.settingsAdjustedWidget) {
            $0.donations.count == 0
        }
    }

    var options: [any TipOption] {
        Tips.MaxDisplayCount(1)
    }
}
