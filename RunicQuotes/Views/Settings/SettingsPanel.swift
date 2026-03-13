//
//  SettingsPanel.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import SwiftUI

struct SettingsPanel<Content: View>: View {
    let palette: AppThemePalette
    let tone: ContentPlateTone
    let content: Content

    init(
        palette: AppThemePalette,
        tone: ContentPlateTone = .secondary,
        @ViewBuilder content: () -> Content,
    ) {
        self.palette = palette
        self.tone = tone
        self.content = content()
    }

    var body: some View {
        ContentPlate(
            palette: self.palette,
            tone: self.tone,
            cornerRadius: self.tone == .hero ? DesignTokens.CornerRadius.xxl : DesignTokens.CornerRadius.xl,
            shadowRadius: self.tone == .hero ? DesignTokens.Elevation.low : 0,
            contentPadding: DesignTokens.Spacing.md,
        ) {
            self.content
        }
    }
}
