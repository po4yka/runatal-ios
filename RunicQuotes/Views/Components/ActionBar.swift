//
//  ActionBar.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import SwiftUI

struct ActionBar<Content: View>: View {
    let palette: AppThemePalette
    @ViewBuilder let content: Content

    var body: some View {
        LiquidActionCluster(palette: self.palette) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                self.content
            }
        }
    }
}
