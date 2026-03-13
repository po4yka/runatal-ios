//
//  SectionLabel.swift
//  RunicQuotes
//
//  Created by Codex on 2026-03-13.
//

import SwiftUI

struct SectionLabel: View {
    let title: String
    let palette: AppThemePalette

    var body: some View {
        Text(title.uppercased())
            .font(DesignTokens.Typography.eyebrow)
            .tracking(1.4)
            .foregroundStyle(palette.textTertiary)
    }
}
