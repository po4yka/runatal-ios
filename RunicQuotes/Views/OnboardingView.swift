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

    @State private var currentPage: Page = .elder
    @State private var selectedScript: RunicScript = .elder
    @State private var selectedStyle: WidgetStyle = .runeFirst

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

            VStack(spacing: 20) {
                header
                progressDots
                pageContent
                navigation
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Welcome to Runic Quotes")
                    .font(.title2.bold())
                    .foregroundColor(.white)

                Text("Choose your script and default widget style.")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.78))
            }

            Spacer()

            Button("Skip") {
                savePreferencesAndFinish()
            }
            .foregroundColor(.white.opacity(0.85))
        }
    }

    private var progressDots: some View {
        HStack(spacing: 8) {
            ForEach(Page.allCases, id: \.rawValue) { page in
                Capsule()
                    .fill(page == currentPage ? Color.white : Color.white.opacity(0.28))
                    .frame(width: page == currentPage ? 24 : 8, height: 8)
                    .animation(.easeInOut(duration: 0.2), value: currentPage)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var pageContent: some View {
        if currentPage == .style {
            styleSelectionCard
        } else {
            if let story = stories[safe: currentPage.rawValue] {
                scriptStoryCard(story)
            }
        }
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
                    .foregroundColor(.white.opacity(0.8))

                Text(runic)
                    .runicTextStyle(
                        script: story.script,
                        font: recommendedFont,
                        style: .title2,
                        minSize: 24,
                        maxSize: 42
                    )
                    .foregroundColor(.white)
                    .lineSpacing(6)
                    .frame(maxWidth: .infinity, minHeight: 140, alignment: .center)

                Text("“\(story.sampleLatin)”")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.86))

                Text(story.script.description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.66))

                Button {
                    selectedScript = story.script
                } label: {
                    HStack {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        Text(isSelected ? "Selected as Default Script" : "Use as Default Script")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isSelected ? Color.white.opacity(0.24) : Color.white.opacity(0.12))
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
                    .foregroundColor(.white.opacity(0.78))

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
                        .foregroundColor(.white)
                        .lineLimit(1)

                    Text(sampleLatin)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(1)
                } else {
                    Text(sampleLatin)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    Text(sampleRunic)
                        .runicTextStyle(
                            script: selectedScript,
                            font: RunicFontConfiguration.recommendedFont(for: selectedScript),
                            style: .caption,
                            minSize: 14,
                            maxSize: 18
                        )
                        .foregroundColor(.white.opacity(0.82))
                        .lineLimit(1)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.white.opacity(0.24) : Color.white.opacity(0.12))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var navigation: some View {
        HStack(spacing: 12) {
            if currentPage != .elder {
                GlassButton.secondary("Back", icon: "chevron.left") {
                    moveBackward()
                }
            }

            GlassButton.primary(
                currentPage == .style ? "Start Reading" : "Next",
                icon: currentPage == .style ? "checkmark.circle.fill" : "arrow.right.circle.fill",
                hapticTier: .newQuote
            ) {
                if currentPage == .style {
                    savePreferencesAndFinish()
                } else {
                    moveForward()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private func moveForward() {
        guard let next = Page(rawValue: currentPage.rawValue + 1) else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            currentPage = next
        }
    }

    private func moveBackward() {
        guard let previous = Page(rawValue: currentPage.rawValue - 1) else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
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
