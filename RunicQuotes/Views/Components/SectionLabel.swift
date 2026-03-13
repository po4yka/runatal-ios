//
//  SectionLabel.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import SwiftUI

struct SectionLabel: View {
    let title: String
    let palette: AppThemePalette

    var body: some View {
        Text(self.title.uppercased())
            .font(DesignTokens.Typography.eyebrow)
            .tracking(1.4)
            .foregroundStyle(self.palette.textTertiary)
    }
}
