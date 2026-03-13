//
//  QuotePackDetailView.swift
//  RunicQuotes
//
//  Created by Claude on 12.03.26.
//

import SwiftData
import SwiftUI

/// Detail view for a single quote pack with description, preview quotes, and install action.
struct QuotePackDetailView: View {
    let pack: QuotePack
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.runicTheme) private var runicTheme
    @Environment(\.userPreferencesRepository) private var preferencesRepository
    @Environment(\.dismiss) private var dismiss
    @State private var showSuccess = false
    @State private var isInstalled = false
    @State private var errorMessage: String?

    private var palette: AppThemePalette {
        .themed(self.runicTheme, for: self.colorScheme)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            LiquidContentScaffold(
                palette: self.palette,
                topPadding: DesignTokens.Spacing.xl,
                spacing: DesignTokens.Spacing.lg,
                showBackgroundExtension: false,
            ) {
                HeroHeader(
                    eyebrow: "Quote Pack",
                    title: self.pack.title,
                    subtitle: self.pack.subtitle,
                    meta: ["\(self.pack.quoteCount) quotes"],
                    palette: self.palette,
                )

                if let errorMessage {
                    FeedbackBanner(
                        palette: self.palette,
                        tone: .error,
                        title: "Couldn't install pack",
                        message: errorMessage,
                    )
                }

                self.packHeader
                self.descriptionSection
                self.previewSection
            }

            if self.showSuccess {
                self.successOverlay
            }
        }
        .navigationTitle(self.pack.title)
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if !self.showSuccess {
                    self.installButton
                }
            }
            .onAppear {
                self.loadInstalledState()
            }
            .alert("Couldn’t Install Pack", isPresented: self.isShowingErrorAlert) {
                Button("OK", role: .cancel) {
                    self.errorMessage = nil
                }
            } message: {
                Text(self.errorMessage ?? "Please try again.")
            }
    }

    // MARK: - Pack Header

    private var packHeader: some View {
        ContentPlate(
            palette: self.palette,
            tone: .hero,
            cornerRadius: DesignTokens.CornerRadius.xxl,
            shadowRadius: DesignTokens.Elevation.medium,
        ) {
            VStack(spacing: DesignTokens.Spacing.sm) {
                Text(self.pack.runicGlyph)
                    .font(.system(size: 48))
                    .foregroundStyle(self.palette.runeText)

                Text(self.pack.title)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(self.palette.textPrimary)

                Text("\(self.pack.quoteCount) quotes \u{00B7} \(self.pack.subtitle)")
                    .font(DesignTokens.Typography.supportingBody)
                    .foregroundStyle(self.palette.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Description

    private var descriptionSection: some View {
        ContentPlate(
            palette: self.palette,
            tone: .secondary,
            cornerRadius: DesignTokens.CornerRadius.xl,
            shadowRadius: 0,
        ) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                SectionLabel(title: "Description", palette: self.palette)
                Text(self.pack.description)
                    .font(DesignTokens.Typography.supportingBody)
                    .foregroundStyle(self.palette.textSecondary)
            }
        }
    }

    // MARK: - Preview Section

    private var previewSection: some View {
        ContentPlate(
            palette: self.palette,
            tone: .secondary,
            cornerRadius: DesignTokens.CornerRadius.xl,
            shadowRadius: 0,
        ) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                SectionLabel(title: "Preview", palette: self.palette)

                ForEach(Array(self.pack.previewQuotes.enumerated()), id: \.offset) { index, quote in
                    HStack(alignment: .top, spacing: DesignTokens.Spacing.sm) {
                        Text("\(index + 1)")
                            .font(DesignTokens.Typography.controlLabel)
                            .foregroundStyle(self.palette.accent)
                            .frame(width: 20, alignment: .trailing)

                        Text("\"\(quote)\"")
                            .font(DesignTokens.Typography.supportingBody)
                            .foregroundStyle(self.palette.textPrimary)
                            .italic()
                    }
                    .padding(.vertical, DesignTokens.Spacing.xxs)

                    if index < self.pack.previewQuotes.count - 1 {
                        Divider()
                            .overlay(self.palette.separator)
                    }
                }
            }
        }
    }

    // MARK: - Install Button

    private var installButton: some View {
        HStack {
            if self.isInstalled {
                Label("Installed", systemImage: "checkmark")
                    .font(DesignTokens.Typography.controlLabel)
                    .foregroundStyle(self.palette.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignTokens.Spacing.sm)
            } else {
                Button {
                    self.installPack()
                } label: {
                    Label("Install Pack", systemImage: "arrow.down.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(LiquidProminentButtonStyle(palette: self.palette, emphasized: true))
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.top, DesignTokens.Spacing.xs)
        .padding(.bottom, DesignTokens.Spacing.lg)
        .background(self.palette.background.opacity(0.96))
    }

    // MARK: - Success Overlay

    private var successOverlay: some View {
        Color.black.opacity(0.14)
            .ignoresSafeArea()
            .overlay {
                ContentPlate(
                    palette: self.palette,
                    tone: .hero,
                    cornerRadius: DesignTokens.CornerRadius.xxl,
                    shadowRadius: DesignTokens.Elevation.hero,
                    contentPadding: DesignTokens.Spacing.xl,
                ) {
                    VStack(spacing: DesignTokens.Spacing.lg) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 54))
                            .foregroundStyle(self.palette.accent)

                        Text("Pack Added")
                            .font(DesignTokens.Typography.pageTitle)
                            .foregroundStyle(self.palette.textPrimary)

                        Text("\(self.pack.quoteCount) quotes from \(self.pack.title) are now in your collection.")
                            .font(DesignTokens.Typography.supportingBody)
                            .foregroundStyle(self.palette.textSecondary)
                            .multilineTextAlignment(.center)

                        Button {
                            self.dismiss()
                        } label: {
                            Text("Explore Pack")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(LiquidProminentButtonStyle(palette: self.palette, emphasized: true))
                    }
                    .frame(maxWidth: 360)
                }
                .padding(DesignTokens.Spacing.xl)
            }
            .transition(.opacity)
    }

    // MARK: - Actions

    private func loadInstalledState() {
        do {
            let preferences = try preferencesRepository.snapshot()
            self.isInstalled = preferences.isPackInstalled(self.pack.id)
        } catch {
            self.isInstalled = false
        }
    }

    private func installPack() {
        do {
            var preferences = try preferencesRepository.snapshot()
            _ = preferences.installPack(self.pack.id)
            try self.preferencesRepository.save(preferences)
            self.isInstalled = true
            withAnimation(.easeInOut(duration: 0.4)) {
                self.showSuccess = true
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    private var isShowingErrorAlert: Binding<Bool> {
        Binding(
            get: { self.errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    self.errorMessage = nil
                }
            },
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        QuotePackDetailView(pack: .sample)
            .modelContainer(ModelContainerHelper.createPlaceholderContainer())
            .environment(\.userPreferencesRepository, PreviewUserPreferencesRepository.shared)
    }
}
