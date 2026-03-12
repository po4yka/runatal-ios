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

/// Five-step onboarding flow: Splash -> Intro -> Atmosphere -> Notifications -> Ready.
struct OnboardingView: View {

    // MARK: - Types

    private enum Page: Int, CaseIterable {
        case splash
        case intro
        case atmosphere
        case notifications
        case ready
    }

    private enum NavigationDirection {
        case forward, backward
    }

    // MARK: - Environment & State

    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme

    @State private var currentPage: Page = .splash
    @State private var selectedScript: RunicScript?
    @State private var navigationDirection: NavigationDirection = .forward
    @State private var notificationsEnabled = false

    let onComplete: () -> Void

    private var palette: AppThemePalette {
        AppThemePalette.adaptive(for: colorScheme)
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
            colors: [palette.background, palette.groupedBG, palette.surface, palette.groupedBG, palette.background],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
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

            Text("R")
                .font(.system(size: 64, weight: .light, design: .serif))
                .foregroundStyle(palette.textPrimary)

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
        VStack(spacing: DesignTokens.Spacing.xl) {
            // Decorative rune glyphs
            Text("\u{16A0}\u{16B1}\u{16BA}\u{16C7}\u{16D2}\u{16A8}\u{16C1}")
                .font(.system(size: 20))
                .foregroundStyle(palette.accent.opacity(0.6))
                .tracking(8)

            VStack(spacing: DesignTokens.Spacing.sm) {
                Text("Ancient Scripts, Modern Wisdom")
                    .font(.title.bold())
                    .foregroundStyle(palette.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Discover the beauty of Elder Futhark, Younger Futhark, and Cirth rune systems")
                    .font(.body)
                    .foregroundStyle(palette.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
    }

    // MARK: - Page: Atmosphere

    private var atmospherePage: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            Text("Choose Your Atmosphere")
                .font(.title2.bold())
                .foregroundStyle(palette.textPrimary)

            VStack(spacing: DesignTokens.Spacing.sm) {
                atmosphereOption(
                    script: .elder,
                    title: "Elder Futhark",
                    subtitle: "2nd-8th century inscriptions and talismans",
                    sampleLatin: "Strength grows in silence."
                )

                atmosphereOption(
                    script: .younger,
                    title: "Younger Futhark",
                    subtitle: "Viking Age carving style with compact forms",
                    sampleLatin: "The sea keeps old vows."
                )

                atmosphereOption(
                    script: .cirth,
                    title: "Cirth",
                    subtitle: "Tolkien-inspired runes for lore and legend",
                    sampleLatin: "Paths awaken beneath the stars."
                )
            }
        }
    }

    private func atmosphereOption(
        script: RunicScript,
        title: String,
        subtitle: String,
        sampleLatin: String
    ) -> some View {
        let isSelected = selectedScript == script
        let runic = RunicTransliterator.transliterate(sampleLatin, to: script)
        let recommendedFont = RunicFontConfiguration.recommendedFont(for: script)

        return GlassCard(
            intensity: isSelected ? .medium : .light,
            cornerRadius: DesignTokens.CornerRadius.lg,
            shadowRadius: isSelected ? 14 : 8
        ) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                    HStack {
                        Text(title)
                            .font(.headline)
                            .foregroundStyle(palette.textPrimary)
                        Spacer()
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.body)
                                .foregroundStyle(palette.accent)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(palette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(runic)
                        .runicTextStyle(
                            script: script,
                            font: recommendedFont,
                            style: .subheadline,
                            minSize: 14,
                            maxSize: 20
                        )
                        .foregroundStyle(palette.runeText)
                        .lineLimit(1)
                        .padding(.top, DesignTokens.Spacing.xxs)
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                .stroke(isSelected ? palette.accent.opacity(0.4) : Color.clear, lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg))
        .onTapGesture {
            Haptics.trigger(.scriptSwitch)
            withAnimation(AnimationPresets.smoothEase) {
                selectedScript = isSelected ? nil : script
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel("\(title) script")
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityHint(isSelected ? "Double tap to deselect" : "Double tap to select")
    }

    // MARK: - Page: Notifications

    private var notificationsPage: some View {
        VStack(spacing: DesignTokens.Spacing.xxl) {
            VStack(spacing: DesignTokens.Spacing.sm) {
                Text("Receive Daily Rune Wisdom")
                    .font(.title2.bold())
                    .foregroundStyle(palette.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Get a new runic quote each day to inspire your journey")
                    .font(.body)
                    .foregroundStyle(palette.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Notification preview card
            GlassCard(intensity: .light, cornerRadius: DesignTokens.CornerRadius.lg) {
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
        .padding(.horizontal, DesignTokens.Spacing.xs)
    }

    // MARK: - Page: Ready

    private var readyPage: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            // Decorative rune glyphs
            Text("\u{16A8}\u{16C7}\u{16B1}\u{16BA}\u{16D2}")
                .font(.system(size: 20))
                .foregroundStyle(palette.accent.opacity(0.6))
                .tracking(8)

            VStack(spacing: DesignTokens.Spacing.sm) {
                Text("Ready to Begin")
                    .font(.title.bold())
                    .foregroundStyle(palette.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Your runic journey starts now")
                    .font(.body)
                    .foregroundStyle(palette.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
    }

    // MARK: - Page Actions

    @ViewBuilder
    private var pageAction: some View {
        switch currentPage {
        case .splash:
            EmptyView()

        case .intro:
            GlassButton.primary("Continue", icon: "arrow.right") {
                Haptics.trigger(.newQuote)
                moveForward()
            }

        case .atmosphere:
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

                Button {
                    Haptics.trigger(.newQuote)
                    moveForward()
                } label: {
                    Text("Not Now")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(palette.textSecondary)
                }
                .buttonStyle(.plain)
            }

        case .ready:
            GlassButton.primary("Enter the Runes", icon: "sparkles") {
                Haptics.trigger(.newQuote)
                savePreferencesAndFinish()
            }
        }
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
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                notificationsEnabled = granted
                moveForward()
            }
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
