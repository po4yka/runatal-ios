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
    let warnings: [String]
    let isRunicRenderingAvailable: Bool

    @State private var cardStyle: ShareCardStyle = .dark
    @State private var isShareSheetPresented = false
    @State private var shareItems: [Any] = []
    @State private var showSavedConfirmation = false
    @State private var isSavingImage = false
    @State private var saveErrorMessage: String?
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
        warnings: [String] = [],
        isRunicRenderingAvailable: Bool = true,
    ) {
        self.runicText = runicText
        self.latinText = latinText
        self.author = author
        self.script = script
        self.font = font
        self.presentationSource = presentationSource
        self.evidenceTier = evidenceTier
        self.primarySourceLabel = primarySourceLabel
        self.warnings = warnings
        self.isRunicRenderingAvailable = isRunicRenderingAvailable
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

                // Full multiline cards remain scrollable in the preview.
                ScrollView {
                    self.shareCardView
                        .padding(.horizontal, DesignTokens.Spacing.xxxl)
                }

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
            .alert("Unable to Save Image", isPresented: self.isSaveErrorPresented) {
                Button("OK", role: .cancel) {
                    self.saveErrorMessage = nil
                }
            } message: {
                Text(self.saveErrorMessage ?? "Please try again.")
            }
            .task(id: self.showSavedConfirmation) {
                guard self.showSavedConfirmation else { return }
                do {
                    try await Task.sleep(for: .milliseconds(1500))
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self.showSavedConfirmation = false
                    }
                } catch {
                    // A new save or dismissal cancels the previous confirmation timer.
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
            warnings: self.warnings,
            isRunicRenderingAvailable: self.isRunicRenderingAvailable,
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
            .disabled(self.isSavingImage)

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
            guard !self.isSavingImage else { return }
            guard let imageData = renderShareImage()?.pngData() else {
                self.saveErrorMessage = PhotoLibraryImageSaveError.renderingFailed.localizedDescription
                return
            }
            self.isSavingImage = true
            self.showSavedConfirmation = false
            Task {
                defer { self.isSavingImage = false }
                do {
                    try await PhotoLibraryImageSaver().save(imageData)
                    Haptics.trigger(.saveOrShare)
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self.showSavedConfirmation = true
                    }
                } catch {
                    self.saveErrorMessage = error.localizedDescription
                }
            }
        #endif
    }

    private var isSaveErrorPresented: Binding<Bool> {
        Binding(
            get: { self.saveErrorMessage != nil },
            set: {
                if !$0 {
                    self.saveErrorMessage = nil
                }
            },
        )
    }

    private var textSharePayload: String {
        var lines = [self.runicText, self.script.displayName, "\"\(self.latinText)\"", "— \(self.author)", self.presentationSource.shareDisclosureTitle]
        if let tier = self.evidenceTier {
            lines.append(self.presentationSource.evidenceLabel(tier))
        }
        if let source = self.primarySourceLabel {
            lines.append(source)
        }
        lines.append(contentsOf: self.warnings)
        return lines.joined(separator: "\n")
    }

    @MainActor
    private func shareAsImage() {
        #if canImport(UIKit)
            Haptics.trigger(.saveOrShare)
            if let image = renderShareImage() {
                self.shareItems = [image]
            } else {
                self.shareItems = [self.textSharePayload]
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
                warnings: warnings,
                isRunicRenderingAvailable: isRunicRenderingAvailable,
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
