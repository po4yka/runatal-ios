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
                topNavBar
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

    private var topNavBar: some View {
        HStack {
            if currentPage != .elder {
                Button {
                    moveBackward()
                } label: {
                    Label("Back", systemImage: "chevron.left")
                }
                .font(.body.weight(.medium))
                .foregroundColor(.white.opacity(0.96))
                .transition(.move(edge: .leading).combined(with: .opacity))
            }

            Spacer()

            Button("Use Defaults") {
                savePreferencesAndFinish()
            }
            .font(.caption.weight(.medium))
            .foregroundColor(.white.opacity(0.7))
        }
        .frame(minHeight: 28)
        .animation(AnimationPresets.smoothEase, value: currentPage)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Welcome to Runic Quotes")
                .font(.title2.bold())
                .foregroundColor(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.9)

            Text(currentPage == .style
                 ? "Pick your default widget style."
                 : "Choose your script.")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .animation(.none, value: currentPage)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var progressDots: some View {
        NativePageControl(
            numberOfPages: Page.allCases.count,
            currentPage: currentPage.rawValue
        )
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
        return GlassCard(opacity: .high, blur: .ultraThinMaterial) {
            VStack(alignment: .leading, spacing: 20) {
                // -- Title block --
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(story.script.displayName)
                            .font(.title3.bold())
                            .foregroundColor(.white)

                        if isSelected {
                            Label("Default", systemImage: "checkmark")
                                .font(.caption2.weight(.semibold))
                                .foregroundColor(.white.opacity(0.55))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule().fill(Color.white.opacity(0.10))
                                )
                                .transition(.scale.combined(with: .opacity))
                        }
                    }

                    Text(story.subtitle)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.55))
                        .fixedSize(horizontal: false, vertical: true)
                }

                // -- Rune preview --
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
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, minHeight: 80, alignment: .center)
                    .shadow(color: .black.opacity(0.5), radius: 6, x: 0, y: 2)
                    .shadow(color: .black.opacity(0.35), radius: 1.5, x: 0, y: 1)

                // -- Quote + meta --
                VStack(alignment: .leading, spacing: 6) {
                    Text("\u{201C}\(story.sampleLatin)\u{201D}")
                        .font(.body.weight(.medium))
                        .foregroundColor(.white.opacity(0.92))
                        .fixedSize(horizontal: false, vertical: true)

                    Text(story.script.description)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.38))
                        .fixedSize(horizontal: false, vertical: true)
                }

                // -- Tap hint --
                if !isSelected {
                    Text("Tap to set as default")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.30))
                        .frame(maxWidth: .infinity)
                        .transition(.opacity)
                }
            }
            .padding(4)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0),
                                .init(color: .clear, location: 0.35),
                                .init(color: .black.opacity(0.28), location: 1.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
        }
        .frame(maxWidth: .infinity)
        .contentShape(RoundedRectangle(cornerRadius: 20))
        .onTapGesture {
            guard !isSelected else { return }
            Haptics.trigger(.scriptSwitch)
            withAnimation(AnimationPresets.smoothEase) {
                selectedScript = story.script
            }
        }
    }

    private var styleSelectionCard: some View {
        GlassCard(opacity: .high, blur: .ultraThinMaterial) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Pick Your Default Widget Style")
                    .font(.title3.bold())
                    .foregroundColor(.white)

                Text("You can change this any time in Settings.")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.55))
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: 10) {
                    styleOption(.runeFirst)
                    styleOption(.translationFirst)
                }
            }
            .padding(4)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0),
                                .init(color: .clear, location: 0.35),
                                .init(color: .black.opacity(0.28), location: 1.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
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
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.white.opacity(0.55))
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
                        .foregroundColor(.white.opacity(0.92))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .shadow(color: .black.opacity(0.34), radius: 1, x: 0, y: 1)

                    Text(sampleLatin)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.38))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text(sampleLatin)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.white.opacity(0.92))
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
                        .foregroundColor(.white.opacity(0.38))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .shadow(color: .black.opacity(0.32), radius: 1, x: 0, y: 1)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.white.opacity(0.22) : Color.white.opacity(0.12))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var navigation: some View {
        HStack {
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
                    currentPage == .style ? "Done" : "Next",
                    systemImage: currentPage == .style ? "checkmark" : "arrow.right"
                )
                .font(.subheadline.weight(.medium))
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.obsidian.palette.ctaAccent)
            .controlSize(.regular)
        }
        .frame(maxWidth: .infinity)
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

/// Wraps `UIPageControl` for native dot styling and VoiceOver "page X of Y".
private struct NativePageControl: UIViewRepresentable {
    var numberOfPages: Int
    var currentPage: Int

    func makeUIView(context: Context) -> UIPageControl {
        let control = UIPageControl()
        control.numberOfPages = numberOfPages
        control.isUserInteractionEnabled = false
        control.currentPageIndicatorTintColor = UIColor.white.withAlphaComponent(0.45)
        control.pageIndicatorTintColor = UIColor.white.withAlphaComponent(0.18)
        control.setContentHuggingPriority(.required, for: .vertical)
        control.preferredCurrentPageIndicatorImage = nil
        applyLeadingTransform(control)
        return control
    }

    func updateUIView(_ control: UIPageControl, context: Context) {
        control.numberOfPages = numberOfPages
        control.currentPage = currentPage
        applyLeadingTransform(control)
    }

    /// Scale dots down and shift so the left edge aligns with content.
    private func applyLeadingTransform(_ control: UIPageControl) {
        let scale: CGFloat = 0.7
        let halfWidth = control.intrinsicContentSize.width / 2
        control.transform = CGAffineTransform(scaleX: scale, y: scale)
            .translatedBy(x: -halfWidth, y: 0)
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
