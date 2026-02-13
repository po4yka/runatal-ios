//
//  OnboardingView.swift
//  RunicQuotes
//
//  Created by Codex on 2026-02-13.
//

import SwiftUI
import SwiftData

/// First-launch onboarding flow introducing scripts and default style selection.
struct OnboardingView: View {
    private enum Page: Int, CaseIterable {
        case elder
        case younger
        case cirth
        case style
    }

    private struct ScriptStory {
        let script: RunicScript
        let subtitle: String
        let sampleLatin: String
    }

    @Environment(\.modelContext) private var modelContext

    private enum NavigationDirection {
        case forward, backward
    }

    @State private var currentPage: Page = .elder
    @State private var selectedScript: RunicScript = .elder
    @State private var selectedStyle: WidgetStyle = .runeFirst
    @State private var navigationDirection: NavigationDirection = .forward

    let onComplete: () -> Void

    private let stories: [ScriptStory] = [
        ScriptStory(
            script: .elder,
            subtitle: "2nd-8th century inscriptions and talismans",
            sampleLatin: "Strength grows in silence."
        ),
        ScriptStory(
            script: .younger,
            subtitle: "Viking Age carving style with compact forms",
            sampleLatin: "The sea keeps old vows."
        ),
        ScriptStory(
            script: .cirth,
            subtitle: "Tolkien-inspired runes for lore and legend",
            sampleLatin: "Paths awaken beneath the stars."
        )
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: AppTheme.obsidian.palette.appBackgroundGradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            RunicAtmosphere(script: selectedScript)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                header
                progressDots
                ScrollView(.vertical, showsIndicators: false) {
                    pageContent
                        .frame(maxWidth: .infinity)
                        .padding(.top, 2)
                        .padding(.bottom, 8)
                }
                .scrollBounceBehavior(.basedOnSize)
                .frame(maxHeight: .infinity)
                navigation
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 16)
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Welcome to Runic Quotes")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)

                Text("Choose your script and default widget style.")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Button("Skip") {
                savePreferencesAndFinish()
            }
            .font(.headline.weight(.medium))
            .foregroundColor(.white.opacity(0.96))
        }
    }

    private var progressDots: some View {
        let accent = AppTheme.obsidian.palette.accent
        return HStack(spacing: 8) {
            ForEach(Page.allCases, id: \.rawValue) { page in
                Capsule()
                    .fill(page == currentPage ? accent : Color.white.opacity(0.46))
                    .frame(width: page == currentPage ? 28 : 8, height: 8)
                    .shadow(
                        color: page == currentPage ? accent.opacity(0.5) : .clear,
                        radius: 4
                    )
                    .animation(.easeInOut(duration: 0.2), value: currentPage)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var pageContent: some View {
        Group {
            if currentPage == .style {
                styleSelectionCard
            } else {
                if let story = stories[safe: currentPage.rawValue] {
                    scriptStoryCard(story)
                }
            }
        }
        .id(currentPage)
        .transition(.asymmetric(
            insertion: .move(edge: navigationDirection == .forward ? .trailing : .leading).combined(with: .opacity),
            removal: .move(edge: navigationDirection == .forward ? .leading : .trailing).combined(with: .opacity)
        ))
    }

    private func scriptStoryCard(_ story: ScriptStory) -> some View {
        let runic = RunicTransliterator.transliterate(story.sampleLatin, to: story.script)
        let isSelected = selectedScript == story.script
        let recommendedFont = RunicFontConfiguration.recommendedFont(for: story.script)

        return GlassCard(opacity: .medium, blur: .regularMaterial) {
            VStack(alignment: .leading, spacing: 16) {
                Text(story.script.displayName)
                    .font(.title3.bold())
                    .foregroundColor(.white)

                Text(story.subtitle)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)

                Text(runic)
                    .runicTextStyle(
                        script: story.script,
                        font: recommendedFont,
                        style: .title2,
                        minSize: 24,
                        maxSize: 42
                    )
                    .foregroundColor(.white.opacity(0.98))
                    .lineSpacing(6)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, minHeight: 120, alignment: .center)
                    .shadow(color: .black.opacity(0.38), radius: 1.5, x: 0, y: 1)

                Text("“\(story.sampleLatin)”")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.92))
                    .fixedSize(horizontal: false, vertical: true)

                Text(story.script.description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    Haptics.trigger(.scriptSwitch)
                    selectedScript = story.script
                } label: {
                    let accent = AppTheme.obsidian.palette.accent
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(isSelected ? accent : .white.opacity(0.7))
                            .symbolEffect(.bounce, value: isSelected)
                            .padding(.top, 2)
                        Text(isSelected ? "Selected as Default Script" : "Tap to Select")
                            .fontWeight(.semibold)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        Spacer(minLength: 8)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isSelected ? accent.opacity(0.15) : Color.white.opacity(0.1))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ? accent.opacity(0.6) : Color.white.opacity(0.15),
                                lineWidth: isSelected ? 1.2 : 0.8
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(4)
        }
        .frame(maxWidth: .infinity)
    }

    private var styleSelectionCard: some View {
        GlassCard(opacity: .medium, blur: .regularMaterial) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Pick Your Default Widget Style")
                    .font(.title3.bold())
                    .foregroundColor(.white)

                Text("You can change this any time in Settings.")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: 10) {
                    styleOption(.runeFirst)
                    styleOption(.translationFirst)
                }
            }
            .padding(4)
        }
    }

    private func styleOption(_ style: WidgetStyle) -> some View {
        let isSelected = selectedStyle == style
        let sampleLatin = "Wisdom travels far."
        let sampleRunic = RunicTransliterator.transliterate(sampleLatin, to: selectedScript)

        return Button {
            selectedStyle = style
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(style.displayName)
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.white)
                    }
                }

                if style == .runeFirst {
                    Text(sampleRunic)
                        .runicTextStyle(
                            script: selectedScript,
                            font: RunicFontConfiguration.recommendedFont(for: selectedScript),
                            style: .headline,
                            minSize: 18,
                            maxSize: 24
                        )
                        .foregroundColor(.white.opacity(0.98))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .shadow(color: .black.opacity(0.34), radius: 1, x: 0, y: 1)

                    Text(sampleLatin)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.88))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text(sampleLatin)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(sampleRunic)
                        .runicTextStyle(
                            script: selectedScript,
                            font: RunicFontConfiguration.recommendedFont(for: selectedScript),
                            style: .caption,
                            minSize: 14,
                            maxSize: 18
                        )
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .shadow(color: .black.opacity(0.32), radius: 1, x: 0, y: 1)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.white.opacity(0.3) : Color.white.opacity(0.18))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var navigation: some View {
        HStack(spacing: 12) {
            if currentPage != .elder {
                Button {
                    moveBackward()
                } label: {
                    Label("Back", systemImage: "chevron.left")
                }
                .buttonStyle(.bordered)
                .frame(minHeight: 44)
                .transition(.move(edge: .leading).combined(with: .opacity))
            }

            Spacer()

            Button {
                Haptics.trigger(.newQuote)
                if currentPage == .style {
                    savePreferencesAndFinish()
                } else {
                    moveForward()
                }
            } label: {
                Label(
                    currentPage == .style ? "Start Reading" : "Next",
                    systemImage: currentPage == .style ? "checkmark.circle.fill" : "arrow.right.circle.fill"
                )
                .font(currentPage == .style ? .headline : .body)
            }
            .buttonStyle(.borderedProminent)
            .frame(minHeight: 44)
            .shadow(
                color: currentPage == .style
                    ? AppTheme.obsidian.palette.accent.opacity(0.4)
                    : .clear,
                radius: 8
            )
        }
        .frame(maxWidth: .infinity)
        .animation(AnimationPresets.smoothEase, value: currentPage)
    }

    private func moveForward() {
        guard let next = Page(rawValue: currentPage.rawValue + 1) else { return }
        navigationDirection = .forward
        withAnimation(AnimationPresets.smoothEase) {
            currentPage = next
        }
    }

    private func moveBackward() {
        guard let previous = Page(rawValue: currentPage.rawValue - 1) else { return }
        navigationDirection = .backward
        withAnimation(AnimationPresets.smoothEase) {
            currentPage = previous
        }
    }

    private func savePreferencesAndFinish() {
        do {
            let preferences = try UserPreferences.getOrCreate(in: modelContext)
            preferences.selectedScript = selectedScript
            preferences.widgetStyle = selectedStyle
            if !preferences.selectedFont.isCompatible(with: selectedScript) {
                preferences.selectedFont = RunicFontConfiguration.recommendedFont(for: selectedScript)
            }
            try modelContext.save()
            NotificationCenter.default.post(name: .preferencesDidChange, object: nil)
        } catch {
            // Continue anyway so onboarding cannot block app usage.
        }

        onComplete()
    }
}

private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    OnboardingView(onComplete: {})
        .modelContainer(for: [Quote.self, UserPreferences.self], inMemory: true)
}
