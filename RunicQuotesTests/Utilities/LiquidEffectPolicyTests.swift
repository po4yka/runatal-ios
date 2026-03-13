//
//  LiquidEffectPolicyTests.swift
//  RunicQuotesTests
//
//  Created by Codex on 2026-03-13.
//

import Testing
@testable import RunicQuotes

@Suite(.tags(.utility))
struct LiquidEffectPolicyTests {
    @Test
    func chromeUsesGlassWhenAccessibilityAllowsIt() {
        let policy = LiquidEffectPolicy(role: .chrome, reduceTransparency: false, isNested: false)
        #expect(policy.shouldUseGlass)
    }

    @Test
    func contentRoleNeverUsesGlass() {
        let policy = LiquidEffectPolicy(role: .content, reduceTransparency: false, isNested: false)
        #expect(!policy.shouldUseGlass)
    }

    @Test
    func nestedGlassIsDisabled() {
        let policy = LiquidEffectPolicy(role: .floatingCallout, reduceTransparency: false, isNested: true)
        #expect(!policy.shouldUseGlass)
    }

    @Test
    func reduceTransparencyDisablesGlass() {
        let policy = LiquidEffectPolicy(role: .chrome, reduceTransparency: true, isNested: false)
        #expect(!policy.shouldUseGlass)
    }
}
