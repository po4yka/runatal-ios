//
//  ScreenScaffold.swift
//  RunicQuotes
//
//  Created by Codex on 2026-03-13.
//

import SwiftUI

struct ScreenScaffold<Content: View>: View {
    let palette: AppThemePalette
    let scrollEnabled: Bool
    let horizontalPadding: CGFloat
    let topPadding: CGFloat
    let spacing: CGFloat
    let content: Content

    init(
        palette: AppThemePalette,
        scrollEnabled: Bool = true,
        horizontalPadding: CGFloat = DesignTokens.Spacing.md,
        topPadding: CGFloat = DesignTokens.Spacing.lg,
        spacing: CGFloat = DesignTokens.Spacing.xl,
        @ViewBuilder content: () -> Content
    ) {
        self.palette = palette
        self.scrollEnabled = scrollEnabled
        self.horizontalPadding = horizontalPadding
        self.topPadding = topPadding
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        ZStack {
            backgroundLayer

            Group {
                if scrollEnabled {
                    ScrollView(showsIndicators: false) {
                        contentStack
                    }
                } else {
                    contentStack
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var contentStack: some View {
        VStack(alignment: .leading, spacing: spacing) {
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, horizontalPadding)
        .padding(.top, topPadding)
        .padding(.bottom, DesignTokens.Spacing.huge + DesignTokens.Spacing.xl)
    }

    private var backgroundLayer: some View {
        LinearGradient(
            colors: palette.heroBackgroundGradient,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(palette.ornamentSecondary)
                .frame(width: 260, height: 260)
                .blur(radius: 100)
                .offset(x: 120, y: -70)
        }
        .overlay(alignment: .bottomLeading) {
            Circle()
                .fill(palette.ornament)
                .frame(width: 300, height: 300)
                .blur(radius: 120)
                .offset(x: -120, y: 120)
        }
        .ignoresSafeArea()
    }
}
