//
//  MetaRow.swift
//  RunicQuotes
//
//  Created by Codex on 2026-03-13.
//

import SwiftUI

struct MetaRow: View {
    let items: [String]
    let palette: AppThemePalette

    private var visibleItems: [String] {
        items.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.xs) {
            ForEach(Array(visibleItems.enumerated()), id: \.offset) { index, item in
                if index > 0 {
                    Circle()
                        .fill(palette.textTertiary.opacity(0.55))
                        .frame(width: 3, height: 3)
                }

                Text(item)
                    .font(DesignTokens.Typography.listMeta)
                    .foregroundStyle(palette.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
