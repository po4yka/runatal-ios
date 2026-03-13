//
//  RunicInlineTip.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import SwiftUI
import TipKit

struct RunicInlineTip<TipContent: Tip>: View {
    let tip: TipContent
    let palette: AppThemePalette
    let refreshID: UUID
    let accessibilityIdentifier: String

    var body: some View {
        TipView(self.tip)
            .tipViewStyle(RunicTipViewStyle(palette: self.palette))
            .id(self.refreshID)
            .accessibilityIdentifier(self.accessibilityIdentifier)
    }
}
