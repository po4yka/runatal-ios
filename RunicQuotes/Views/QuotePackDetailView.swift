//
//  QuotePackDetailView.swift
//  RunicQuotes
//
//  Created by Claude on 2026-03-12.
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
        .themed(runicTheme, for: colorScheme)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            LiquidContentScaffold(
                palette: palette,
                topPadding: DesignTokens.Spacing.xl,
                spacing: DesignTokens.Spacing.lg,
                showBackgroundExtension: false
            ) {
                HeroHeader(
                    eyebrow: "Quote Pack",
                    title: pack.title,
                    subtitle: pack.subtitle,
                    meta: ["\(pack.quoteCount) quotes"],
                    palette: palette
                )

                if let errorMessage {
                    FeedbackBanner(
                        palette: palette,
                        tone: .error,
                        title: "Couldn't install pack",
                        message: errorMessage
                    )
                }

                packHeader
                descriptionSection
                previewSection
            }

            if showSuccess {
                successOverlay
            }
        }
        .navigationTitle(pack.title)
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if !showSuccess {
                installButton
            }
        }
        .onAppear {
            loadInstalledState()
        }
        .alert("Couldn’t Install Pack", isPresented: isShowingErrorAlert) {
            Button("OK", role: .cancel) {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "Please try again.")
        }
    }

    // MARK: - Pack Header

    @ViewBuilder
    private var packHeader: some View {
        ContentPlate(
            palette: palette,
            tone: .hero,
            cornerRadius: DesignTokens.CornerRadius.xxl,
            shadowRadius: DesignTokens.Elevation.medium
        ) {
            VStack(spacing: DesignTokens.Spacing.sm) {
                Text(pack.runicGlyph)
                    .font(.system(size: 48))
                    .foregroundStyle(palette.runeText)

                Text(pack.title)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(palette.textPrimary)

                Text("\(pack.quoteCount) quotes \u{00B7} \(pack.subtitle)")
                    .font(DesignTokens.Typography.supportingBody)
                    .foregroundStyle(palette.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Description

    @ViewBuilder
    private var descriptionSection: some View {
        ContentPlate(
            palette: palette,
            tone: .secondary,
            cornerRadius: DesignTokens.CornerRadius.xl,
            shadowRadius: 0
        ) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                SectionLabel(title: "Description", palette: palette)
                Text(pack.description)
                    .font(DesignTokens.Typography.supportingBody)
                    .foregroundStyle(palette.textSecondary)
            }
        }
    }

    // MARK: - Preview Section

    @ViewBuilder
    private var previewSection: some View {
        ContentPlate(
            palette: palette,
            tone: .secondary,
            cornerRadius: DesignTokens.CornerRadius.xl,
            shadowRadius: 0
        ) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                SectionLabel(title: "Preview", palette: palette)

                ForEach(Array(pack.previewQuotes.enumerated()), id: \.offset) { index, quote in
                    HStack(alignment: .top, spacing: DesignTokens.Spacing.sm) {
                        Text("\(index + 1)")
                            .font(DesignTokens.Typography.controlLabel)
                            .foregroundStyle(palette.accent)
                            .frame(width: 20, alignment: .trailing)

                        Text("\"\(quote)\"")
                            .font(DesignTokens.Typography.supportingBody)
                            .foregroundStyle(palette.textPrimary)
                            .italic()
                    }
                    .padding(.vertical, DesignTokens.Spacing.xxs)

                    if index < pack.previewQuotes.count - 1 {
                        Divider()
                            .overlay(palette.separator)
                    }
                }
            }
        }
    }

    // MARK: - Install Button

    @ViewBuilder
    private var installButton: some View {
        HStack {
            if isInstalled {
                Label("Installed", systemImage: "checkmark")
                    .font(DesignTokens.Typography.controlLabel)
                    .foregroundStyle(palette.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignTokens.Spacing.sm)
            } else {
                Button {
                    installPack()
                } label: {
                    Label("Install Pack", systemImage: "arrow.down.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(LiquidProminentButtonStyle(palette: palette, emphasized: true))
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.top, DesignTokens.Spacing.xs)
        .padding(.bottom, DesignTokens.Spacing.lg)
        .background(palette.background.opacity(0.96))
    }

    // MARK: - Success Overlay

    @ViewBuilder
    private var successOverlay: some View {
        Color.black.opacity(0.14)
            .ignoresSafeArea()
            .overlay {
                ContentPlate(
                    palette: palette,
                    tone: .hero,
                    cornerRadius: DesignTokens.CornerRadius.xxl,
                    shadowRadius: DesignTokens.Elevation.hero,
                    contentPadding: DesignTokens.Spacing.xl
                ) {
                    VStack(spacing: DesignTokens.Spacing.lg) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 54))
                            .foregroundStyle(palette.accent)

                        Text("Pack Added")
                            .font(DesignTokens.Typography.pageTitle)
                            .foregroundStyle(palette.textPrimary)

                        Text("\(pack.quoteCount) quotes from \(pack.title) are now in your collection.")
                            .font(DesignTokens.Typography.supportingBody)
                            .foregroundStyle(palette.textSecondary)
                            .multilineTextAlignment(.center)

                        Button {
                            dismiss()
                        } label: {
                            Text("Explore Pack")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(LiquidProminentButtonStyle(palette: palette, emphasized: true))
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
            isInstalled = preferences.isPackInstalled(pack.id)
        } catch {
            isInstalled = false
        }
    }

    private func installPack() {
        do {
            var preferences = try preferencesRepository.snapshot()
            _ = preferences.installPack(pack.id)
            try preferencesRepository.save(preferences)
            isInstalled = true
            withAnimation(.easeInOut(duration: 0.4)) {
                showSuccess = true
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private var isShowingErrorAlert: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    errorMessage = nil
                }
            }
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
