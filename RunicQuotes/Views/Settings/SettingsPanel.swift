//
//  SettingsPanel.swift
//  RunicQuotes
//
//  Created by Codex on 2026-03-13.
//

import SwiftUI

struct SettingsPanel<Content: View>: View {
    let palette: AppThemePalette
    let tone: ContentPlateTone
    let content: Content

    init(
        palette: AppThemePalette,
        tone: ContentPlateTone = .secondary,
        @ViewBuilder content: () -> Content
    ) {
        self.palette = palette
        self.tone = tone
        self.content = content()
    }

    var body: some View {
        ContentPlate(
            palette: palette,
            tone: tone,
            cornerRadius: tone == .hero ? DesignTokens.CornerRadius.xxl : DesignTokens.CornerRadius.xl,
            shadowRadius: tone == .hero ? DesignTokens.Elevation.low : 0,
            contentPadding: DesignTokens.Spacing.md
        ) {
            content
        }
    }
}
