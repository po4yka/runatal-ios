//
//  LiquidContentScaffold.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import SwiftUI

struct LiquidContentScaffold<Content: View>: View {
    let palette: AppThemePalette
    let scrollEnabled: Bool
    let horizontalPadding: CGFloat
    let topPadding: CGFloat
    let spacing: CGFloat
    let showBackgroundExtension: Bool
    let content: Content

    init(
        palette: AppThemePalette,
        scrollEnabled: Bool = true,
        horizontalPadding: CGFloat = DesignTokens.Spacing.md,
        topPadding: CGFloat = DesignTokens.Spacing.lg,
        spacing: CGFloat = DesignTokens.Spacing.xl,
        showBackgroundExtension: Bool = true,
        @ViewBuilder content: () -> Content,
    ) {
        self.palette = palette
        self.scrollEnabled = scrollEnabled
        self.horizontalPadding = horizontalPadding
        self.topPadding = topPadding
        self.spacing = spacing
        self.showBackgroundExtension = showBackgroundExtension
        self.content = content()
    }

    var body: some View {
        ZStack {
            self.backgroundLayer

            Group {
                if self.scrollEnabled {
                    ScrollView(showsIndicators: false) {
                        self.contentStack
                    }
                } else {
                    self.contentStack
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .backgroundExtensionEffect(isEnabled: self.showBackgroundExtension)
    }

    private var contentStack: some View {
        VStack(alignment: .leading, spacing: self.spacing) {
            self.content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, self.horizontalPadding)
        .padding(.top, self.topPadding)
        .padding(.bottom, DesignTokens.Spacing.huge + DesignTokens.Spacing.xl)
    }

    private var backgroundLayer: some View {
        LinearGradient(
            colors: self.palette.immersiveBackgroundGradient,
            startPoint: .topLeading,
            endPoint: .bottomTrailing,
        )
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(self.palette.chromeTint)
                .frame(width: 220, height: 220)
                .blur(radius: 80)
                .offset(x: 90, y: -40)
        }
        .overlay(alignment: .bottomLeading) {
            Circle()
                .fill(self.palette.ornament)
                .frame(width: 260, height: 260)
                .blur(radius: 110)
                .offset(x: -100, y: 110)
        }
        .ignoresSafeArea()
    }
}
