//
//  ActionBar.swift
//  RunicQuotes
//
//  Created by Codex on 2026-03-13.
//

import SwiftUI

struct ActionBar<Content: View>: View {
    let palette: AppThemePalette
    let content: Content

    init(
        palette: AppThemePalette,
        @ViewBuilder content: () -> Content
    ) {
        self.palette = palette
        self.content = content()
    }

    var body: some View {
        LiquidActionCluster(palette: palette) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                content
            }
        }
    }
}
