//
//  LiquidEffectPolicyTests.swift
//  RunicQuotesTests
//
//  Created by Codex on 2026-03-13.
//

import XCTest
@testable import RunicQuotes

final class LiquidEffectPolicyTests: XCTestCase {
    func testChromeUsesGlassWhenAccessibilityAllowsIt() {
        let policy = LiquidEffectPolicy(
            role: .chrome,
            reduceTransparency: false,
            isNested: false
        )

        XCTAssertTrue(policy.shouldUseGlass)
    }

    func testContentRoleNeverUsesGlass() {
        let policy = LiquidEffectPolicy(
            role: .content,
            reduceTransparency: false,
            isNested: false
        )

        XCTAssertFalse(policy.shouldUseGlass)
    }

    func testNestedGlassIsDisabled() {
        let policy = LiquidEffectPolicy(
            role: .floatingCallout,
            reduceTransparency: false,
            isNested: true
        )

        XCTAssertFalse(policy.shouldUseGlass)
    }

    func testReduceTransparencyDisablesGlass() {
        let policy = LiquidEffectPolicy(
            role: .chrome,
            reduceTransparency: true,
            isNested: false
        )

        XCTAssertFalse(policy.shouldUseGlass)
    }
}
