//
//  FeatureDiscoveryController.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import Foundation
import os
import TipKit

@MainActor
final class FeatureDiscoveryController: ObservableObject {
    enum TestingMode: Equatable {
        case live
        case hidden
        case showAll
    }

    enum HomeTestingSequence: Equatable {
        case hidden
        case nextQuote
        case saveQuote
    }

    @Published private(set) var refreshID = UUID()
    @Published private(set) var homeTestingSequence: HomeTestingSequence = .hidden

    private static let logger = Logger(subsystem: AppConstants.loggingSubsystem, category: "FeatureDiscovery")

    private(set) var testingMode: TestingMode = .live
    private var hasCompletedOnboarding = false
    private var isHomeQuoteReady = false
    private var hasAdvancedHomeQuote = false
    private var hasSavedHomeQuote = false

    func configureForLaunch(processInfo: ProcessInfo = .processInfo) {
        self.testingMode = Self.testingMode(for: processInfo.environment)
        self.hasCompletedOnboarding = Self.hasCompletedOnboarding(for: processInfo.environment)
        FeatureDiscoveryState.hasCompletedOnboarding = self.hasCompletedOnboarding
        FeatureDiscoveryState.homeQuoteReady = self.isHomeQuoteReady
        self.refreshHomeTestingSequence()

        if processInfo.environment["TIPKIT_RESET"] == "1" {
            do {
                try Tips.resetDatastore()
            } catch {
                Self.logger.error("Failed to reset TipKit datastore: \(error.localizedDescription)")
            }
        }

        do {
            try Self.configureTipsDatastore()
            self.applyTestingMode()
        } catch {
            Self.logger.error("Failed to configure TipKit: \(error.localizedDescription)")
        }
    }

    func replayTips() throws {
        self.hasAdvancedHomeQuote = false
        self.hasSavedHomeQuote = false
        try Self.resetTipsDatastore()
        try Self.configureTipsDatastore()
        self.applyTestingMode()
        FeatureDiscoveryState.hasCompletedOnboarding = self.hasCompletedOnboarding
        FeatureDiscoveryState.homeQuoteReady = self.isHomeQuoteReady
        self.refreshHomeTestingSequence()
        self.refreshID = UUID()
    }

    func updateOnboardingCompleted(_ hasCompletedOnboarding: Bool) {
        self.hasCompletedOnboarding = hasCompletedOnboarding
        FeatureDiscoveryState.hasCompletedOnboarding = hasCompletedOnboarding
        self.refreshHomeTestingSequence()
    }

    func updateHomeQuoteReady(_ isReady: Bool) {
        self.isHomeQuoteReady = isReady
        FeatureDiscoveryState.homeQuoteReady = isReady
        self.refreshHomeTestingSequence()
    }

    func recordHomeQuoteAdvanced() {
        self.hasAdvancedHomeQuote = true
        self.refreshHomeTestingSequence()
    }

    func recordHomeQuoteSaved() {
        self.hasSavedHomeQuote = true
        self.refreshHomeTestingSequence()
    }

    static func testingMode(for environment: [String: String]) -> TestingMode {
        if environment["TIPKIT_SHOW_ALL"] == "1" {
            return .showAll
        }

        if environment["TIPKIT_LIVE"] == "1" {
            return .live
        }

        if environment["UI_TESTING"] == "1" {
            return .hidden
        }

        return .live
    }

    private static func hasCompletedOnboarding(for environment: [String: String]) -> Bool {
        if environment["SKIP_ONBOARDING"] == "1" {
            return true
        }

        return UserDefaults.standard.bool(forKey: AppConstants.onboardingCompletedKey)
    }

    static func preview() -> FeatureDiscoveryController {
        let controller = FeatureDiscoveryController()
        controller.updateOnboardingCompleted(true)
        controller.updateHomeQuoteReady(true)
        return controller
    }

    private static func configureTipsDatastore() throws {
        do {
            try Tips.configure([
                .displayFrequency(.hourly),
                .datastoreLocation(.applicationDefault)
            ])
        } catch {
            guard !Self.isAlreadyConfiguredError(error) else {
                return
            }

            throw error
        }
    }

    private static func resetTipsDatastore() throws {
        do {
            try Tips.resetDatastore()
        } catch {
            guard !Self.isAlreadyConfiguredError(error) else {
                return
            }

            throw error
        }
    }

    private func applyTestingMode() {
        switch self.testingMode {
        case .live:
            break
        case .hidden:
            Tips.hideAllTipsForTesting()
        case .showAll:
            Tips.showAllTipsForTesting()
        }
    }

    private func refreshHomeTestingSequence() {
        guard self.hasCompletedOnboarding, self.isHomeQuoteReady else {
            self.homeTestingSequence = .hidden
            return
        }

        if self.hasSavedHomeQuote {
            self.homeTestingSequence = .hidden
        } else if self.hasAdvancedHomeQuote {
            self.homeTestingSequence = .saveQuote
        } else {
            self.homeTestingSequence = .nextQuote
        }
    }

    private static func isAlreadyConfiguredError(_ error: Error) -> Bool {
        String(describing: error).contains("tipsDatastoreAlreadyConfigured")
    }
}
