//
//  LiquidListScaffold.swift
//  RunicQuotes
//
//  Created by Codex on 2026-03-13.
//

import SwiftUI

struct LiquidListScaffold<Content: View>: View {
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
        List {
            content
                .listRowBackground(Color.clear)
        }
        .scrollContentBackground(.hidden)
        .background(backgroundLayer)
    }

    private var backgroundLayer: some View {
        LinearGradient(
            colors: [palette.canvasBase, palette.canvasSecondary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}
