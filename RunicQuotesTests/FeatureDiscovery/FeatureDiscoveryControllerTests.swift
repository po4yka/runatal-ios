//
//  FeatureDiscoveryControllerTests.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

@testable import RunicQuotes
import Testing
import TipKit

@MainActor
@Suite(.serialized, .tags(.utility))
struct FeatureDiscoveryControllerTests {
    @Test
    func ingModeReturnsLiveByDefault() {
        #expect(FeatureDiscoveryController.testingMode(for: [:]) == .live)
    }

    @Test
    func ingModeReturnsHiddenForUITesting() {
        #expect(FeatureDiscoveryController.testingMode(for: ["UI_TESTING": "1"]) == .hidden)
    }

    @Test
    func ingModePrefersShowAllOverride() {
        #expect(
            FeatureDiscoveryController.testingMode(for: [
                "UI_TESTING": "1",
                "TIPKIT_SHOW_ALL": "1",
            ]) == .showAll,
        )
    }

    @Test
    func ingModeAllowsLiveTipsDuringUITestingWhenRequested() {
        #expect(
            FeatureDiscoveryController.testingMode(for: [
                "UI_TESTING": "1",
                "TIPKIT_LIVE": "1",
            ]) == .live,
        )
    }

    @Test
    func replayTipsUpdatesRefreshIDAndPreservesEligibilityParameters() throws {
        try self.resetTipKitState()
        defer { resetTipKitStateSilently() }

        let controller = FeatureDiscoveryController()
        controller.updateOnboardingCompleted(true)
        controller.updateHomeQuoteReady(true)

        let previousRefreshID = controller.refreshID
        try controller.replayTips()

        #expect(controller.refreshID != previousRefreshID)
        #expect(FeatureDiscoveryState.hasCompletedOnboarding)
        #expect(FeatureDiscoveryState.homeQuoteReady)
    }

    @Test
    func homeTestingSequenceAdvancesThroughNextAndSaveFlow() {
        let controller = FeatureDiscoveryController()
        controller.updateOnboardingCompleted(true)
        controller.updateHomeQuoteReady(true)

        #expect(controller.homeTestingSequence == .nextQuote)

        controller.recordHomeQuoteAdvanced()
        #expect(controller.homeTestingSequence == .saveQuote)

        controller.recordHomeQuoteSaved()
        #expect(controller.homeTestingSequence == .hidden)
    }

    @Test
    func replayTipsResetsHomeTestingSequence() throws {
        try self.resetTipKitState()
        defer { resetTipKitStateSilently() }

        let controller = FeatureDiscoveryController()
        controller.updateOnboardingCompleted(true)
        controller.updateHomeQuoteReady(true)
        controller.recordHomeQuoteAdvanced()
        controller.recordHomeQuoteSaved()

        try controller.replayTips()

        #expect(controller.homeTestingSequence == .nextQuote)
    }

    private func resetTipKitState() throws {
        try? Tips.resetDatastore()
        UserDefaults.standard.removeObject(forKey: AppConstants.onboardingCompletedKey)
    }

    private func resetTipKitStateSilently() {
        try? Tips.resetDatastore()
        UserDefaults.standard.removeObject(forKey: AppConstants.onboardingCompletedKey)
    }
}
