//
//  DynamicTypeSupportTests.swift
//  RunicQuotes
//
//  Created by Claude on 09.10.26.
//

@testable import RunicQuotes
import SwiftUI
import Testing

@MainActor
@Suite(.tags(.utility))
struct DynamicTypeSupportTests {
    @Test
    func runicDesignBoundsApplyBeforeSystemTextStyleScaling() {
        let body = RunicDynamicTypeModifier(script: .elder, font: .noto, textStyle: .body, minSize: 12, maxSize: 30)
        let smallTitle = RunicDynamicTypeModifier(script: .cirth, font: .cirth, textStyle: .title, minSize: 12, maxSize: 24)
        let enlargedCaption = RunicDynamicTypeModifier(script: .younger, font: .babelstone, textStyle: .caption, minSize: 18, maxSize: 30)
        #expect(body.basePointSize == 17)
        #expect(smallTitle.basePointSize == 24)
        #expect(enlargedCaption.basePointSize == 18)
    }
}
