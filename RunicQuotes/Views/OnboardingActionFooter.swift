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
        LiquidActionCluster(palette: palette) {
            switch currentPage {
            case .splash:
                EmptyView()
            case .intro, .atmosphere:
                primaryButton("Continue", systemImage: "arrow.right") {
                    Haptics.trigger(.newQuote)
                    moveForward()
                }
            case .notifications:
                primaryButton("Enable Notifications", systemImage: "bell") {
                    Haptics.trigger(.newQuote)
                    requestNotifications()
                }

                Button("Not Now") {
                    Haptics.trigger(.newQuote)
                    moveForward()
                }
                .buttonStyle(LiquidProminentButtonStyle(palette: palette, emphasized: false))
            case .ready:
                primaryButton("Enter the Runes", systemImage: "sparkles") {
                    Haptics.trigger(.newQuote)
                    savePreferencesAndFinish()
                }
            }
        }
        .frame(maxWidth: 420)
    }

    private func primaryButton(
        _ title: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(LiquidProminentButtonStyle(palette: palette, emphasized: true))
    }
}
