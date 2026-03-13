//
//  OnboardingActionFooter.swift
//  RunicQuotes
//
//  Created by Claude on 2026-03-13.
//

import SwiftUI

/// Footer actions for the onboarding flow.
struct OnboardingActionFooter: View {
    let currentPage: OnboardingView.Page
    let palette: AppThemePalette
    let requestNotifications: () -> Void
    let moveForward: () -> Void
    let savePreferencesAndFinish: () -> Void

    var body: some View {
        switch currentPage {
        case .splash:
            EmptyView()
        case .intro, .atmosphere:
            GlassButton.primary("Continue", icon: "arrow.right") {
                Haptics.trigger(.newQuote)
                moveForward()
            }
        case .notifications:
            VStack(spacing: DesignTokens.Spacing.sm) {
                GlassButton.primary("Enable Notifications", icon: "bell") {
                    Haptics.trigger(.newQuote)
                    requestNotifications()
                }

                Button("Not Now") {
                    Haptics.trigger(.newQuote)
                    moveForward()
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(palette.textSecondary)
                .buttonStyle(.plain)
            }
        case .ready:
            GlassButton.primary("Enter the Runes", icon: "sparkles") {
                Haptics.trigger(.newQuote)
                savePreferencesAndFinish()
            }
        }
    }
}
