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
    @State private var selectedScript: RunicScript?
    @State private var selectedStyle: WidgetStyle = .runeFirst
    @State private var navigationDirection: NavigationDirection = .forward

    /// Falls back to the current page's script when nothing is explicitly selected.
    private var displayedScript: RunicScript {
        selectedScript ?? stories[safe: currentPage.rawValue]?.script ?? .elder
    }

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
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: AppTheme.obsidian.palette.appBackgroundGradient,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                RunicAtmosphere(script: displayedScript)
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    header

                    ScrollView(.vertical, showsIndicators: false) {
                        pageContent
                            .frame(maxWidth: .infinity)
                            .padding(.top, 2)
                            .padding(.bottom, 8)
                    }
                    .scrollBounceBehavior(.basedOnSize)
                    .gesture(
                        DragGesture(minimumDistance: 40, coordinateSpace: .local)
                            .onEnded { value in
                                let horizontal = value.translation.width
                                guard abs(horizontal) > abs(value.translation.height) else { return }
                                if horizontal < 0 {
                                    moveForward()
                                } else {
                                    moveBackward()
                                }
                            }
                    )

                    Spacer(minLength: 0)

                    VStack(spacing: 14) {
                        progressDots
                        navigation
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar { onboardingToolbar }
        }
    }

    @ToolbarContentBuilder
    private var onboardingToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            if currentPage != .elder {
                Button {
                    moveBackward()
                } label: {
                    Label("Back", systemImage: "chevron.left")
                        .font(.body.weight(.medium))
                }
                .foregroundColor(.white.opacity(0.92))
                .transition(.move(edge: .leading).combined(with: .opacity))
            }
        }

        ToolbarItem(placement: .topBarTrailing) {
            Button("Use defaults") {
                savePreferencesAndFinish()
            }
            .font(.subheadline.weight(.medium))
            .foregroundColor(.white.opacity(0.55))
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Welcome to Runic quotes")
                .font(.title2.bold())
                .foregroundColor(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.9)

            Text(currentPage == .style
                 ? "Pick your default widget style"
                 : "Choose your script")
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
        .frame(maxWidth: .infinity, alignment: .center)
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
        return GlassCard(
            opacity: .high,
            blur: .ultraThinMaterial,
            shadowRadius: isSelected ? 14 : 10
        ) {
            VStack(alignment: .leading, spacing: 20) {
                // -- Title block --
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(story.script.displayName)
                            .font(.title3.bold())
                            .foregroundColor(.white)

                        Spacer()

                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title3)
                                .foregroundColor(.white.opacity(0.55))
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
                        .foregroundColor(.white.opacity(0.50))
                        .fixedSize(horizontal: false, vertical: true)
                }

                // -- Tap hint --
                if !isSelected {
                    Text("Tap to set as default")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.42))
                        .frame(maxWidth: .infinity)
                        .transition(.opacity)
                }
            }
            .padding(6)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(isSelected ? 0.06 : 0))
                .allowsHitTesting(false)
        )
        .frame(maxWidth: .infinity)
        .contentShape(RoundedRectangle(cornerRadius: 20))
        .onTapGesture {
            Haptics.trigger(.scriptSwitch)
            withAnimation(AnimationPresets.smoothEase) {
                selectedScript = isSelected ? nil : story.script
            }
        }
    }

    private var styleSelectionCard: some View {
        let sampleLatin = "Wisdom travels far."
        let sampleRunic = RunicTransliterator.transliterate(sampleLatin, to: displayedScript)
        let recommendedFont = RunicFontConfiguration.recommendedFont(for: displayedScript)

        return GlassCard(opacity: .high, blur: .ultraThinMaterial) {
            VStack(alignment: .leading, spacing: 14) {
                Text("You can change this any time in settings.")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.55))
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: 0) {
                    styleRow(
                        style: .runeFirst,
                        sampleLatin: sampleLatin,
                        sampleRunic: sampleRunic,
                        recommendedFont: recommendedFont
                    )

                    Rectangle()
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 1)
                        .padding(.horizontal, 4)

                    styleRow(
                        style: .translationFirst,
                        sampleLatin: sampleLatin,
                        sampleRunic: sampleRunic,
                        recommendedFont: recommendedFont
                    )
                }
            }
            .padding(6)
        }
    }

    private func styleRow(
        style: WidgetStyle,
        sampleLatin: String,
        sampleRunic: String,
        recommendedFont: RunicFont
    ) -> some View {
        let isSelected = selectedStyle == style

        return Button {
            selectedStyle = style
        } label: {
            VStack(alignment: .leading, spacing: 6) {
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
                            script: displayedScript,
                            font: recommendedFont,
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
                        .foregroundColor(.white.opacity(0.50))
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
                            script: displayedScript,
                            font: recommendedFont,
                            style: .caption,
                            minSize: 14,
                            maxSize: 18
                        )
                        .foregroundColor(.white.opacity(0.50))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .shadow(color: .black.opacity(0.32), radius: 1, x: 0, y: 1)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(isSelected ? 0.08 : 0))
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
                HStack(spacing: 6) {
                    Text(currentPage == .style ? "Done" : "Next")
                    Image(systemName: currentPage == .style ? "checkmark" : "arrow.right")
                        .font(.caption.weight(.semibold))
                }
                .font(.subheadline.weight(.medium))
                .foregroundColor(.white.opacity(0.92))
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .opacity(0.8)
                )
                .shadow(color: .black.opacity(0.22), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(PlainButtonStyle())
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
            preferences.selectedScript = displayedScript
            preferences.widgetStyle = selectedStyle
            if !preferences.selectedFont.isCompatible(with: displayedScript) {
                preferences.selectedFont = RunicFontConfiguration.recommendedFont(for: displayedScript)
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
        return control
    }

    func updateUIView(_ control: UIPageControl, context: Context) {
        control.numberOfPages = numberOfPages
        control.currentPage = currentPage
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
