//
//  ShareQuoteView.swift
//  RunicQuotes
//
//  Created by Claude on 12.03.26.
//

import SwiftUI
#if canImport(UIKit)
    import UIKit
#endif

// MARK: - Share Card Style

/// Visual style for the share card image.
enum ShareCardStyle: String, Codable, CaseIterable, Identifiable {
    case dark
    case light

    var id: String {
        rawValue
    }

    var displayName: String {
        switch self {
        case .dark: "Dark"
        case .light: "Light"
        }
    }
}

// MARK: - ShareQuoteView

/// Dedicated share preview screen matching Figma Share page.
/// Shows a styled quote card preview with Copy / Save / Share actions.
struct ShareQuoteView: View {

    // MARK: - Properties

    let runicText: String
    let latinText: String
    let author: String
    let script: RunicScript
    let font: RunicFont
    let presentationSource: RunicPresentationSource
    let evidenceTier: TranslationEvidenceTier?
    let primarySourceLabel: String?

    @State private var cardStyle: ShareCardStyle = .dark
    @State private var isShareSheetPresented = false
    @State private var shareItems: [Any] = []
    @State private var showSavedConfirmation = false
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.runicTheme) private var runicTheme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.displayScale) private var displayScale

    init(
        runicText: String,
        latinText: String,
        author: String,
        script: RunicScript,
        font: RunicFont,
        presentationSource: RunicPresentationSource = .storedTransliteration,
        evidenceTier: TranslationEvidenceTier? = nil,
        primarySourceLabel: String? = nil,
    ) {
        self.runicText = runicText
        self.latinText = latinText
        self.author = author
        self.script = script
        self.font = font
        self.presentationSource = presentationSource
        self.evidenceTier = evidenceTier
        self.primarySourceLabel = primarySourceLabel
    }

    // MARK: - Body

    var body: some View {
        let palette = AppThemePalette.themed(self.runicTheme, for: self.colorScheme)

        ZStack {
            // Background
            LinearGradient(
                colors: palette.appBackgroundGradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing,
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Card preview
                self.shareCardView
                    .padding(.horizontal, DesignTokens.Spacing.xxxl)

                Spacer()

                // Card style picker
                Picker("Card Style", selection: self.$cardStyle) {
                    ForEach(ShareCardStyle.allCases) { style in
                        Text(style.displayName).tag(style)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, DesignTokens.Spacing.huge)
                .padding(.bottom, DesignTokens.Spacing.xl)

                // Action bar
                self.actionBar(palette: palette)
                    .padding(.bottom, DesignTokens.Spacing.xl)
            }
        }
        .navigationTitle("Share")
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        self.shareAsImage()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .symbolRenderingMode(.monochrome)
                    }
                }
            }
            .sheet(isPresented: self.$isShareSheetPresented) {
                #if canImport(UIKit)
                    ActivityViewControllerWrapper(activityItems: self.shareItems)
                #else
                    Text("Sharing is unavailable on this platform.")
                        .padding()
                #endif
            }
            .overlay {
                if self.showSavedConfirmation {
                    self.savedConfirmationOverlay(palette: AppThemePalette.themed(self.runicTheme, for: self.colorScheme))
                }
            }
    }

    // MARK: - Share Card

    private var shareCardView: some View {
        ShareCardContent(
            runicText: self.runicText,
            latinText: self.latinText,
            author: self.author,
            script: self.script,
            font: self.font,
            style: self.cardStyle,
            presentationSource: self.presentationSource,
            evidenceTier: self.evidenceTier,
            primarySourceLabel: self.primarySourceLabel,
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xl))
        .shadow(
            color: .black.opacity(0.3),
            radius: 20,
            x: 0,
            y: 8,
        )
    }

    // MARK: - Action Bar

    private func actionBar(palette: AppThemePalette) -> some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            self.actionButton(
                icon: "doc.on.doc",
                label: "Copy",
                palette: palette,
            ) {
                self.copyQuoteText()
            }

            self.actionButton(
                icon: "square.and.arrow.down",
                label: "Save",
                palette: palette,
            ) {
                self.saveImage()
            }

            self.actionButton(
                icon: "square.and.arrow.up",
                label: "Share",
                palette: palette,
            ) {
                self.shareAsImage()
            }
        }
    }

    private func actionButton(
        icon: String,
        label: String,
        palette: AppThemePalette,
        action: @escaping () -> Void,
    ) -> some View {
        Button(action: action) {
            VStack(spacing: DesignTokens.Spacing.xs) {
                ZStack {
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xl)
                        .fill(DesignTokens.GlassColor.background(for: self.colorScheme))
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xl)
                        .strokeBorder(
                            DesignTokens.GlassColor.border(for: self.colorScheme),
                            lineWidth: 0.5,
                        )
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(palette.textSecondary)
                }
                .frame(width: 44, height: 44)
                .shadow(
                    color: .black.opacity(0.12),
                    radius: 12,
                    x: 0,
                    y: 4,
                )

                Text(label)
                    .font(DesignTokens.Typography.controlLabel)
                    .foregroundStyle(palette.textTertiary)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func copyQuoteText() {
        Haptics.trigger(.saveOrShare)
        let payload = "\"\(latinText)\"\n-- \(author)"
        #if canImport(UIKit)
            UIPasteboard.general.string = payload
        #endif
    }

    @MainActor
    private func saveImage() {
        #if canImport(UIKit)
            Haptics.trigger(.saveOrShare)
            guard let image = renderShareImage() else { return }
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            withAnimation(.easeInOut(duration: 0.3)) {
                self.showSavedConfirmation = true
            }
            Task {
                try? await Task.sleep(for: .milliseconds(1500))
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.showSavedConfirmation = false
                }
            }
        #endif
    }

    @MainActor
    private func shareAsImage() {
        #if canImport(UIKit)
            Haptics.trigger(.saveOrShare)
            if let image = renderShareImage() {
                self.shareItems = [image]
            } else {
                self.shareItems = ["\"\(self.latinText)\"\n-- \(self.author)"]
            }
            self.isShareSheetPresented = true
        #endif
    }

    #if canImport(UIKit)
        @MainActor
        private func renderShareImage() -> UIImage? {
            let cardContent = ShareCardContent(
                runicText: runicText,
                latinText: latinText,
                author: author,
                script: script,
                font: font,
                style: cardStyle,
                presentationSource: presentationSource,
                evidenceTier: evidenceTier,
                primarySourceLabel: primarySourceLabel,
            )
            .frame(width: AppConstants.shareSnapshotWidth)

            let renderer = ImageRenderer(content: cardContent)
            renderer.scale = self.displayScale
            return renderer.uiImage
        }
    #endif

    // MARK: - Saved Confirmation

    private func savedConfirmationOverlay(palette: AppThemePalette) -> some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 36))
                .foregroundStyle(palette.success)
            Text("Saved to Photos")
                .font(.headline)
                .foregroundStyle(palette.textPrimary)
        }
        .padding(DesignTokens.Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                .fill(.ultraThinMaterial),
        )
        .transition(.opacity.combined(with: .scale(scale: 0.9)))
    }
}

// MARK: - Share Card Content

/// The styled share card used for both preview and image rendering.
/// Always uses dark palette for the dark card style, white bg for light.
struct ShareCardContent: View {
    let runicText: String
    let latinText: String
    let author: String
    let script: RunicScript
    let font: RunicFont
    let style: ShareCardStyle
    let presentationSource: RunicPresentationSource
    let evidenceTier: TranslationEvidenceTier?
    let primarySourceLabel: String?

    private var cardBG: Color {
        self.style == .dark ? Color(hex: 0x0C1118) : .white
    }

    private var cardBorder: Color {
        self.style == .dark
            ? Color.white.opacity(0.06)
            : Color(hex: 0x48566A).opacity(0.12)
    }

    /// Dark card always uses dark palette colors, light card uses light palette
    private var cardPalette: AppThemePalette {
        self.style == .dark
            ? .adaptive(for: .dark)
            : .adaptive(for: .light)
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: DesignTokens.Spacing.xxl)

            // Decorative rune ornament
            self.runeOrnament
                .padding(.bottom, DesignTokens.Spacing.xl)

            // Runic text (smaller, secondary)
            Text(self.runicText)
                .runicTextStyle(
                    script: self.script,
                    font: self.font,
                    style: .caption,
                    minSize: 11,
                    maxSize: 14,
                )
                .foregroundStyle(self.cardPalette.textSecondary.opacity(0.5))
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .tracking(1.12)
                .padding(.horizontal, DesignTokens.Spacing.xl)

            // Separator
            Rectangle()
                .fill(self.cardPalette.separator.opacity(0.5))
                .frame(height: 0.5)
                .frame(maxWidth: 80)
                .padding(.vertical, DesignTokens.Spacing.md)

            // Quote text
            Text("\u{201C}\(self.latinText)\u{201D}")
                .font(.custom(RunicFontConfiguration.serifFontName, size: 15, relativeTo: .body))
                .foregroundStyle(self.cardPalette.textPrimary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, DesignTokens.Spacing.xxl)

            // Author
            Text(self.author)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(self.cardPalette.textSecondary)
                .padding(.top, DesignTokens.Spacing.sm)

            // Dot ornament
            self.dotOrnament
                .padding(.top, DesignTokens.Spacing.lg)

            // Branding
            self.brandingLabel
                .padding(.top, DesignTokens.Spacing.lg)

            self.disclosureLabel
                .padding(.top, DesignTokens.Spacing.sm)

            Spacer()
                .frame(height: DesignTokens.Spacing.xxl)
        }
        .frame(maxWidth: .infinity)
        .background(self.cardBG)
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xl)
                .strokeBorder(self.cardBorder, lineWidth: 0.5),
        )
    }

    // MARK: - Ornaments

    private var runeOrnament: some View {
        // Decorative SVG-like ornament from Figma (three-line mark)
        HStack(spacing: 4) {
            ForEach(0 ..< 3, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 1)
                    .fill(self.cardPalette.textTertiary.opacity(0.3))
                    .frame(width: 8, height: 2)
            }
        }
    }

    private var dotOrnament: some View {
        HStack(spacing: 4) {
            ForEach(0 ..< 3, id: \.self) { _ in
                Circle()
                    .fill(self.cardPalette.textTertiary.opacity(0.12))
                    .frame(width: 3, height: 3)
            }
        }
    }

    private var brandingLabel: some View {
        HStack(spacing: DesignTokens.Spacing.xs) {
            Text("\u{16B1}")
                .font(.system(size: 8))
                .foregroundStyle(self.cardPalette.textTertiary)
            Text("Runic Quotes")
                .font(.system(size: 10))
                .foregroundStyle(self.cardPalette.textTertiary)
        }
    }

    private var disclosureLabel: some View {
        VStack(spacing: 2) {
            Text(self.presentationSource.shareDisclosureTitle)
                .font(.system(size: 9))
                .foregroundStyle(self.cardPalette.textTertiary)

            if let evidenceTier {
                Text(evidenceTier.displayName)
                    .font(.system(size: 9))
                    .foregroundStyle(self.cardPalette.textTertiary.opacity(0.9))
            } else if let primarySourceLabel {
                Text(primarySourceLabel)
                    .font(.system(size: 9))
                    .foregroundStyle(self.cardPalette.textTertiary.opacity(0.9))
                    .lineLimit(1)
            }
        }
    }
}

// MARK: - UIKit Wrappers

#if canImport(UIKit)
    private struct ActivityViewControllerWrapper: UIViewControllerRepresentable {
        let activityItems: [Any]

        func makeUIViewController(context: Context) -> UIActivityViewController {
            UIActivityViewController(activityItems: self.activityItems, applicationActivities: nil)
        }

        func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
    }
#endif

// MARK: - Preview

#Preview("Dark Card") {
    NavigationStack {
        ShareQuoteView(
            runicText: "\u{16BE}\u{16A9}\u{16CF} \u{16A8}\u{16DA}\u{16DA} \u{16CF}\u{16BA}\u{16A9}\u{16CB}\u{16A2} \u{16E5}\u{16BA}\u{16A9} \u{16E5}\u{16A8}\u{16BE}\u{16DE}\u{16A2}\u{16B1} \u{16A8}\u{16B1}\u{16A2} \u{16DA}",
            latinText: "Not all those who wander are lost.",
            author: "J.R.R. Tolkien",
            script: .elder,
            font: .noto,
        )
    }
}
