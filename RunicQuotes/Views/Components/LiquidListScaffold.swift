//
//  LiquidListScaffold.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import SwiftUI

struct LiquidListScaffold<Content: View>: View {
    let palette: AppThemePalette
    @ViewBuilder let content: Content

    var body: some View {
        List {
            self.content
                .listRowBackground(Color.clear)
        }
        .scrollContentBackground(.hidden)
        .background(self.backgroundLayer)
    }

    private var backgroundLayer: some View {
        LinearGradient(
            colors: [self.palette.canvasBase, self.palette.canvasSecondary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing,
        )
        .ignoresSafeArea()
    }
}
