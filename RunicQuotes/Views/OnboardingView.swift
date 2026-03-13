//
//  OnboardingView.swift
//  RunicQuotes
//
//  Created by Claude on 13.02.26.
//

import os
import SwiftUI
import UserNotifications

// swiftlint:disable type_body_length
/// Five-step onboarding flow: Splash -> Intro -> Atmosphere -> Notifications -> Ready.
struct OnboardingView: View {

    // MARK: - Types

    enum Page: Int, CaseIterable {
        case splash
        case intro
        case atmosphere
        case notifications
        case ready
    }

    enum NavigationDirection {
        case forward, backward
    }

    // MARK: - Environment & State

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.runicTheme) private var runicTheme
    @Environment(\.userPreferencesRepository) private var preferencesRepository

    @State private var currentPage: Page = .splash
    @State private var selectedScript: RunicScript?
    @State private var navigationDirection: NavigationDirection = .forward
    @State private var notificationsEnabled = false

    let onComplete: () -> Void

    private var palette: AppThemePalette {
        AppThemePalette.themed(self.runicTheme, for: self.colorScheme)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            self.backgroundGradient
            RunicAtmosphere(script: self.selectedScript ?? .elder)
                .ignoresSafeArea()
                .opacity(0.05)

            VStack(spacing: 0) {
                Spacer(minLength: 0)

                self.pageContent
                    .frame(maxWidth: .infinity)

                Spacer(minLength: 0)

                if self.currentPage != .splash {
                    VStack(spacing: DesignTokens.Spacing.sm) {
                        self.progressDots
                        self.pageAction
                    }
                    .padding(.bottom, DesignTokens.Spacing.xxl)
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.xxl)
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        LinearGradient(
            colors: self.palette.immersiveBackgroundGradient,
            startPoint: .topLeading,
            endPoint: .bottomTrailing,
        )
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(self.palette.chromeTint)
                .frame(width: 180, height: 180)
                .blur(radius: 80)
                .offset(x: 84, y: -24)
        }
        .overlay(alignment: .bottomLeading) {
            Circle()
                .fill(self.palette.ornament)
                .frame(width: 220, height: 220)
                .blur(radius: 100)
                .offset(x: -94, y: 104)
        }
        .ignoresSafeArea()
    }

    // MARK: - Progress Dots

    private var progressDots: some View {
        // Only show for pages after splash (4 dots for intro..ready)
        let totalDots = Page.allCases.count - 1
        let currentDot = self.currentPage.rawValue - 1

        return HStack(spacing: DesignTokens.Spacing.xs) {
            ForEach(0 ..< totalDots, id: \.self) { index in
                Circle()
                    .fill(index == currentDot ? self.palette.accent : self.palette.textTertiary.opacity(0.4))
                    .frame(width: 6, height: 6)
            }
        }
    }

    // MARK: - Page Content

    private var pageContent: some View {
        Group {
            switch self.currentPage {
            case .splash:
                self.splashPage
            case .intro:
                self.introPage
            case .atmosphere:
                self.atmospherePage
            case .notifications:
                self.notificationsPage
            case .ready:
                self.readyPage
            }
        }
        .id(self.currentPage)
        .transition(.asymmetric(
            insertion: .move(edge: self.navigationDirection == .forward ? .trailing : .leading).combined(with: .opacity),
            removal: .move(edge: self.navigationDirection == .forward ? .leading : .trailing).combined(with: .opacity),
        ))
    }

    // MARK: - Page: Splash

    private var splashPage: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            Spacer()

            VStack(spacing: DesignTokens.Spacing.sm) {
                Text("ᚱ")
                    .font(.system(size: 72, weight: .light, design: .serif))
                    .foregroundStyle(self.palette.runeText)

                Text("RunicQuotes")
                    .font(DesignTokens.Typography.heroCompact)
                    .foregroundStyle(self.palette.textPrimary)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            // Auto-advance after 2 seconds
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            self.moveForward()
        }
    }

    // MARK: - Page: Intro

    private var introPage: some View {
        LiquidCard(
            palette: self.palette,
            role: .chrome,
            cornerRadius: DesignTokens.CornerRadius.xxl,
            shadowRadius: DesignTokens.Elevation.hero,
            contentPadding: DesignTokens.Spacing.xl,
        ) {
            VStack(spacing: DesignTokens.Spacing.lg) {
                Text("\u{16A0}\u{16B1}\u{16BA}\u{16C7}\u{16D2}\u{16A8}\u{16C1}")
                    .font(.system(size: 20))
                    .foregroundStyle(self.palette.accent.opacity(0.65))
                    .tracking(8)

                HeroHeader(
                    eyebrow: "Welcome",
                    title: "Ancient scripts, modern ritual",
                    subtitle: "Begin with a quieter reading cadence and choose the alphabet that feels like yours.",
                    meta: ["Elder Futhark", "Younger Futhark", "Cirth"],
                    palette: self.palette,
                    alignment: .center,
                )
            }
        }
    }

    // MARK: - Page: Atmosphere

    private var atmospherePage: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            HeroHeader(
                eyebrow: "Choose Tone",
                title: "Pick the script that sets the mood",
                subtitle: "This becomes your default atmosphere when the app opens.",
                meta: ["You can change it later in Settings"],
                palette: self.palette,
                alignment: .center,
            )

            VStack(spacing: DesignTokens.Spacing.sm) {
                OnboardingAtmosphereOption(
                    script: .elder,
                    title: "Elder Futhark",
                    subtitle: "2nd-8th century inscriptions and talismans",
                    sampleLatin: "Strength grows in silence.",
                    selectedScript: self.selectedScript,
                    palette: self.palette,
                ) { newSelection in
                    Haptics.trigger(.scriptSwitch)
                    withAnimation(AnimationPresets.smoothEase) {
                        self.selectedScript = newSelection
                    }
                }

                OnboardingAtmosphereOption(
                    script: .younger,
                    title: "Younger Futhark",
                    subtitle: "Viking Age carving style with compact forms",
                    sampleLatin: "The sea keeps old vows.",
                    selectedScript: self.selectedScript,
                    palette: self.palette,
                ) { newSelection in
                    Haptics.trigger(.scriptSwitch)
                    withAnimation(AnimationPresets.smoothEase) {
                        self.selectedScript = newSelection
                    }
                }

                OnboardingAtmosphereOption(
                    script: .cirth,
                    title: "Cirth",
                    subtitle: "Tolkien-inspired runes for lore and legend",
                    sampleLatin: "Paths awaken beneath the stars.",
                    selectedScript: self.selectedScript,
                    palette: self.palette,
                ) { newSelection in
                    Haptics.trigger(.scriptSwitch)
                    withAnimation(AnimationPresets.smoothEase) {
                        self.selectedScript = newSelection
                    }
                }
            }
        }
    }

    // MARK: - Page: Notifications

    private var notificationsPage: some View {
        LiquidCard(
            palette: self.palette,
            role: .chrome,
            cornerRadius: DesignTokens.CornerRadius.xxl,
            shadowRadius: DesignTokens.Elevation.chrome,
            contentPadding: DesignTokens.Spacing.xl,
        ) {
            VStack(spacing: DesignTokens.Spacing.xl) {
                HeroHeader(
                    eyebrow: "Cadence",
                    title: "Receive a daily rune",
                    subtitle: "Let one line arrive on its own rhythm instead of asking you to remember.",
                    meta: ["Optional", "Can be changed later"],
                    palette: self.palette,
                    alignment: .center,
                )

                InsetCard(palette: self.palette, cornerRadius: DesignTokens.CornerRadius.lg) {
                    HStack(spacing: DesignTokens.Spacing.sm) {
                        Image(systemName: "bell.badge")
                            .font(.title2)
                            .foregroundStyle(self.palette.accent)

                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                            Text("Daily Rune")
                                .font(.headline)
                                .foregroundStyle(self.palette.textPrimary)
                            Text("Your morning wisdom awaits")
                                .font(.subheadline)
                                .foregroundStyle(self.palette.textSecondary)
                        }

                        Spacer()
                    }
                }
            }
        }
    }

    // MARK: - Page: Ready

    private var readyPage: some View {
        LiquidCard(
            palette: self.palette,
            role: .chrome,
            cornerRadius: DesignTokens.CornerRadius.xxl,
            shadowRadius: DesignTokens.Elevation.hero,
            contentPadding: DesignTokens.Spacing.xl,
        ) {
            VStack(spacing: DesignTokens.Spacing.lg) {
                Text("\u{16A8}\u{16C7}\u{16B1}\u{16BA}\u{16D2}")
                    .font(.system(size: 20))
                    .foregroundStyle(self.palette.accent.opacity(0.6))
                    .tracking(8)

                HeroHeader(
                    eyebrow: "Begin",
                    title: "Ready to read",
                    subtitle: "Your defaults are set. Step into the library and let the first passage arrive.",
                    meta: [self.notificationsEnabled ? "Notifications on" : "Notifications optional"],
                    palette: self.palette,
                    alignment: .center,
                )
            }
        }
    }

    // MARK: - Page Actions

    private var pageAction: some View {
        OnboardingActionFooter(
            currentPage: self.currentPage,
            palette: self.palette,
            requestNotifications: self.requestNotifications,
            moveForward: self.moveForward,
            savePreferencesAndFinish: self.savePreferencesAndFinish,
        )
    }

    // MARK: - Navigation

    private func moveForward() {
        guard let next = Page(rawValue: currentPage.rawValue + 1) else { return }
        self.navigationDirection = .forward
        withAnimation(AnimationPresets.smoothEase) {
            self.currentPage = next
        }
    }

    private func moveBackward() {
        guard let previous = Page(rawValue: currentPage.rawValue - 1),
              previous != .splash else { return }
        self.navigationDirection = .backward
        withAnimation(AnimationPresets.smoothEase) {
            self.currentPage = previous
        }
    }

    // MARK: - Notifications

    private func requestNotifications() {
        Task {
            let granted = await (try? UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound],
            )) ?? false
            self.notificationsEnabled = granted
            self.moveForward()
        }
    }

    // MARK: - Persistence

    private static let logger = Logger(subsystem: AppConstants.loggingSubsystem, category: "Onboarding")

    private func savePreferencesAndFinish() {
        do {
            let script = self.selectedScript ?? .elder
            var preferences = try preferencesRepository.snapshot()
            preferences.selectedScript = script
            if !preferences.selectedFont.isCompatible(with: script) {
                preferences.selectedFont = RunicFontConfiguration.recommendedFont(for: script)
            }
            try self.preferencesRepository.save(preferences)
            NotificationCenter.default.post(name: .preferencesDidChange, object: nil)
        } catch {
            Self.logger.error("Failed to save onboarding preferences: \(error.localizedDescription)")
        }

        self.onComplete()
    }
}

// MARK: - Preview

#Preview {
    OnboardingView(onComplete: {})
        .modelContainer(for: [Quote.self, UserPreferences.self], inMemory: true)
        .environment(\.userPreferencesRepository, PreviewUserPreferencesRepository.shared)
}

// swiftlint:enable type_body_length
