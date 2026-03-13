//
//  MetaRow.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import SwiftUI

struct MetaRow: View {
    let items: [String]
    let palette: AppThemePalette

    private var visibleItems: [String] {
        self.items.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.xs) {
            ForEach(Array(self.visibleItems.enumerated()), id: \.offset) { index, item in
                if index > 0 {
                    Circle()
                        .fill(self.palette.textTertiary.opacity(0.55))
                        .frame(width: 3, height: 3)
                }

                Text(item)
                    .font(DesignTokens.Typography.listMeta)
                    .foregroundStyle(self.palette.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
