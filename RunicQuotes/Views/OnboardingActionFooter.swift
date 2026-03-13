//
//  OnboardingActionFooter.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
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
        LiquidActionCluster(palette: self.palette) {
            switch self.currentPage {
            case .splash:
                EmptyView()
            case .intro, .atmosphere:
                self.primaryButton("Continue", systemImage: "arrow.right") {
                    Haptics.trigger(.newQuote)
                    self.moveForward()
                }
            case .notifications:
                self.primaryButton("Enable Notifications", systemImage: "bell") {
                    Haptics.trigger(.newQuote)
                    self.requestNotifications()
                }

                Button("Not Now") {
                    Haptics.trigger(.newQuote)
                    self.moveForward()
                }
                .buttonStyle(LiquidProminentButtonStyle(palette: self.palette, emphasized: false))
            case .ready:
                self.primaryButton("Enter the Runes", systemImage: "sparkles") {
                    Haptics.trigger(.newQuote)
                    self.savePreferencesAndFinish()
                }
            }
        }
        .frame(maxWidth: 420)
    }

    private func primaryButton(
        _ title: String,
        systemImage: String,
        action: @escaping () -> Void,
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(LiquidProminentButtonStyle(palette: self.palette, emphasized: true))
    }
}
