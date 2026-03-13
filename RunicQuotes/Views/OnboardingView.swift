//
//  OnboardingView.swift
//  RunicQuotes
//
//  Created by Codex on 2026-02-13.
//

import SwiftUI
import SwiftData
import UserNotifications
import os

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

    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.runicTheme) private var runicTheme

    @State private var currentPage: Page = .splash
    @State private var selectedScript: RunicScript?
    @State private var navigationDirection: NavigationDirection = .forward
    @State private var notificationsEnabled = false

    let onComplete: () -> Void

    private var palette: AppThemePalette {
        AppThemePalette.themed(runicTheme, for: colorScheme)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            backgroundGradient
            RunicAtmosphere(script: selectedScript ?? .elder)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 0)

                pageContent
                    .frame(maxWidth: .infinity)

                Spacer(minLength: 0)

                if currentPage != .splash {
                    VStack(spacing: DesignTokens.Spacing.sm) {
                        progressDots
                        pageAction
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
            colors: palette.heroBackgroundGradient,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(palette.ornamentSecondary)
                .frame(width: 240, height: 240)
                .blur(radius: 100)
                .offset(x: 100, y: -40)
        }
        .overlay(alignment: .bottomLeading) {
            Circle()
                .fill(palette.ornament)
                .frame(width: 280, height: 280)
                .blur(radius: 120)
                .offset(x: -120, y: 120)
        }
        .ignoresSafeArea()
    }

    // MARK: - Progress Dots

    private var progressDots: some View {
        // Only show for pages after splash (4 dots for intro..ready)
        let totalDots = Page.allCases.count - 1
        let currentDot = currentPage.rawValue - 1

        return HStack(spacing: DesignTokens.Spacing.xs) {
            ForEach(0..<totalDots, id: \.self) { index in
                Circle()
                    .fill(index == currentDot ? palette.accent : palette.textTertiary.opacity(0.4))
                    .frame(width: 6, height: 6)
            }
        }
    }

    // MARK: - Page Content

    @ViewBuilder
    private var pageContent: some View {
        Group {
            switch currentPage {
            case .splash:
                splashPage
            case .intro:
                introPage
            case .atmosphere:
                atmospherePage
            case .notifications:
                notificationsPage
            case .ready:
                readyPage
            }
        }
        .id(currentPage)
        .transition(.asymmetric(
            insertion: .move(edge: navigationDirection == .forward ? .trailing : .leading).combined(with: .opacity),
            removal: .move(edge: navigationDirection == .forward ? .leading : .trailing).combined(with: .opacity)
        ))
    }

    // MARK: - Page: Splash

    private var splashPage: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            Spacer()

            VStack(spacing: DesignTokens.Spacing.sm) {
                Text("ᚱ")
                    .font(.system(size: 72, weight: .light, design: .serif))
                    .foregroundStyle(palette.runeText)

                Text("RunicQuotes")
                    .font(DesignTokens.Typography.heroCompact)
                    .foregroundStyle(palette.textPrimary)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            // Auto-advance after 2 seconds
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            moveForward()
        }
    }

    // MARK: - Page: Intro

    private var introPage: some View {
        EditorialCard(
            palette: palette,
            tone: .hero,
            cornerRadius: DesignTokens.CornerRadius.xxl,
            shadowRadius: DesignTokens.Elevation.hero,
            contentPadding: DesignTokens.Spacing.xl
        ) {
            VStack(spacing: DesignTokens.Spacing.lg) {
                Text("\u{16A0}\u{16B1}\u{16BA}\u{16C7}\u{16D2}\u{16A8}\u{16C1}")
                    .font(.system(size: 20))
                    .foregroundStyle(palette.accent.opacity(0.65))
                    .tracking(8)

                HeroHeader(
                    eyebrow: "Welcome",
                    title: "Ancient scripts, modern ritual",
                    subtitle: "Begin with a quieter reading cadence and choose the alphabet that feels like yours.",
                    meta: ["Elder Futhark", "Younger Futhark", "Cirth"],
                    palette: palette,
                    alignment: .center
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
                palette: palette,
                alignment: .center
            )

            VStack(spacing: DesignTokens.Spacing.sm) {
                OnboardingAtmosphereOption(
                    script: .elder,
                    title: "Elder Futhark",
                    subtitle: "2nd-8th century inscriptions and talismans",
                    sampleLatin: "Strength grows in silence.",
                    selectedScript: selectedScript,
                    palette: palette
                ) { newSelection in
                    Haptics.trigger(.scriptSwitch)
                    withAnimation(AnimationPresets.smoothEase) {
                        selectedScript = newSelection
                    }
                }

                OnboardingAtmosphereOption(
                    script: .younger,
                    title: "Younger Futhark",
                    subtitle: "Viking Age carving style with compact forms",
                    sampleLatin: "The sea keeps old vows.",
                    selectedScript: selectedScript,
                    palette: palette
                ) { newSelection in
                    Haptics.trigger(.scriptSwitch)
                    withAnimation(AnimationPresets.smoothEase) {
                        selectedScript = newSelection
                    }
                }

                OnboardingAtmosphereOption(
                    script: .cirth,
                    title: "Cirth",
                    subtitle: "Tolkien-inspired runes for lore and legend",
                    sampleLatin: "Paths awaken beneath the stars.",
                    selectedScript: selectedScript,
                    palette: palette
                ) { newSelection in
                    Haptics.trigger(.scriptSwitch)
                    withAnimation(AnimationPresets.smoothEase) {
                        selectedScript = newSelection
                    }
                }
            }
        }
    }

    // MARK: - Page: Notifications

    private var notificationsPage: some View {
        EditorialCard(
            palette: palette,
            tone: .primary,
            cornerRadius: DesignTokens.CornerRadius.xxl,
            shadowRadius: DesignTokens.Elevation.medium,
            contentPadding: DesignTokens.Spacing.xl
        ) {
            VStack(spacing: DesignTokens.Spacing.xl) {
                HeroHeader(
                    eyebrow: "Cadence",
                    title: "Receive a daily rune",
                    subtitle: "Let one line arrive on its own rhythm instead of asking you to remember.",
                    meta: ["Optional", "Can be changed later"],
                    palette: palette,
                    alignment: .center
                )

                InsetCard(palette: palette, cornerRadius: DesignTokens.CornerRadius.lg) {
                    HStack(spacing: DesignTokens.Spacing.sm) {
                        Image(systemName: "bell.badge")
                            .font(.title2)
                            .foregroundStyle(palette.accent)

                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                            Text("Daily Rune")
                                .font(.headline)
                                .foregroundStyle(palette.textPrimary)
                            Text("Your morning wisdom awaits")
                                .font(.subheadline)
                                .foregroundStyle(palette.textSecondary)
                        }

                        Spacer()
                    }
                }
            }
        }
    }

    // MARK: - Page: Ready

    private var readyPage: some View {
        EditorialCard(
            palette: palette,
            tone: .hero,
            cornerRadius: DesignTokens.CornerRadius.xxl,
            shadowRadius: DesignTokens.Elevation.hero,
            contentPadding: DesignTokens.Spacing.xl
        ) {
            VStack(spacing: DesignTokens.Spacing.lg) {
                Text("\u{16A8}\u{16C7}\u{16B1}\u{16BA}\u{16D2}")
                    .font(.system(size: 20))
                    .foregroundStyle(palette.accent.opacity(0.6))
                    .tracking(8)

                HeroHeader(
                    eyebrow: "Begin",
                    title: "Ready to read",
                    subtitle: "Your defaults are set. Step into the library and let the first passage arrive.",
                    meta: [notificationsEnabled ? "Notifications on" : "Notifications optional"],
                    palette: palette,
                    alignment: .center
                )
            }
        }
    }

    // MARK: - Page Actions

    @ViewBuilder
    private var pageAction: some View {
        OnboardingActionFooter(
            currentPage: currentPage,
            palette: palette,
            requestNotifications: requestNotifications,
            moveForward: moveForward,
            savePreferencesAndFinish: savePreferencesAndFinish
        )
    }

    // MARK: - Navigation

    private func moveForward() {
        guard let next = Page(rawValue: currentPage.rawValue + 1) else { return }
        navigationDirection = .forward
        withAnimation(AnimationPresets.smoothEase) {
            currentPage = next
        }
    }

    private func moveBackward() {
        guard let previous = Page(rawValue: currentPage.rawValue - 1),
              previous != .splash else { return }
        navigationDirection = .backward
        withAnimation(AnimationPresets.smoothEase) {
            currentPage = previous
        }
    }

    // MARK: - Notifications

    private func requestNotifications() {
        Task {
            let granted = (try? await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            )) ?? false
            notificationsEnabled = granted
            moveForward()
        }
    }

    // MARK: - Persistence

    private static let logger = Logger(subsystem: AppConstants.loggingSubsystem, category: "Onboarding")

    private func savePreferencesAndFinish() {
        do {
            let preferences = try UserPreferences.getOrCreate(in: modelContext)
            let script = selectedScript ?? .elder
            preferences.selectedScript = script
            if !preferences.selectedFont.isCompatible(with: script) {
                preferences.selectedFont = RunicFontConfiguration.recommendedFont(for: script)
            }
            try modelContext.save()
            NotificationCenter.default.post(name: .preferencesDidChange, object: nil)
        } catch {
            Self.logger.error("Failed to save onboarding preferences: \(error.localizedDescription)")
        }

        onComplete()
    }
}

// MARK: - Preview

#Preview {
    OnboardingView(onComplete: {})
        .modelContainer(for: [Quote.self, UserPreferences.self], inMemory: true)
}
// swiftlint:enable type_body_length
