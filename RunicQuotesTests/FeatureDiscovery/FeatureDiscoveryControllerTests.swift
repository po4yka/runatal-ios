//
//  FeatureDiscoveryControllerTests.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

@testable import RunicQuotes
import TipKit
import XCTest

@MainActor
final class FeatureDiscoveryControllerTests: XCTestCase {
    override func setUpWithError() throws {
        try super.setUpWithError()
        try? Tips.resetDatastore()
        UserDefaults.standard.removeObject(forKey: AppConstants.onboardingCompletedKey)
    }

    override func tearDownWithError() throws {
        try? Tips.resetDatastore()
        UserDefaults.standard.removeObject(forKey: AppConstants.onboardingCompletedKey)
        try super.tearDownWithError()
    }

    func testTestingModeReturnsLiveByDefault() {
        XCTAssertEqual(FeatureDiscoveryController.testingMode(for: [:]), .live)
    }

    func testTestingModeReturnsHiddenForUITesting() {
        XCTAssertEqual(
            FeatureDiscoveryController.testingMode(for: ["UI_TESTING": "1"]),
            .hidden,
        )
    }

    func testTestingModePrefersShowAllOverride() {
        XCTAssertEqual(
            FeatureDiscoveryController.testingMode(for: [
                "UI_TESTING": "1",
                "TIPKIT_SHOW_ALL": "1",
            ]),
            .showAll,
        )
    }

    func testTestingModeAllowsLiveTipsDuringUITestingWhenRequested() {
        XCTAssertEqual(
            FeatureDiscoveryController.testingMode(for: [
                "UI_TESTING": "1",
                "TIPKIT_LIVE": "1",
            ]),
            .live,
        )
    }

    func testReplayTipsUpdatesRefreshIDAndPreservesEligibilityParameters() throws {
        let controller = FeatureDiscoveryController()
        controller.updateOnboardingCompleted(true)
        controller.updateHomeQuoteReady(true)

        let previousRefreshID = controller.refreshID

        try controller.replayTips()

        XCTAssertNotEqual(controller.refreshID, previousRefreshID)
        XCTAssertTrue(FeatureDiscoveryState.hasCompletedOnboarding)
        XCTAssertTrue(FeatureDiscoveryState.homeQuoteReady)
    }

    func testHomeTestingSequenceAdvancesThroughNextAndSaveFlow() {
        let controller = FeatureDiscoveryController()

        controller.updateOnboardingCompleted(true)
        controller.updateHomeQuoteReady(true)
        XCTAssertEqual(controller.homeTestingSequence, .nextQuote)

        controller.recordHomeQuoteAdvanced()
        XCTAssertEqual(controller.homeTestingSequence, .saveQuote)

        controller.recordHomeQuoteSaved()
        XCTAssertEqual(controller.homeTestingSequence, .hidden)
    }

    func testReplayTipsResetsHomeTestingSequence() throws {
        let controller = FeatureDiscoveryController()
        controller.updateOnboardingCompleted(true)
        controller.updateHomeQuoteReady(true)
        controller.recordHomeQuoteAdvanced()
        controller.recordHomeQuoteSaved()

        try controller.replayTips()

        XCTAssertEqual(controller.homeTestingSequence, .nextQuote)
    }
}
