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
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showSuccess = false
    @State private var isInstalled = false
    @State private var errorMessage: String?

    private var palette: AppThemePalette {
        .adaptive(for: colorScheme)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                    packHeader
                    descriptionSection
                    previewSection
                    Spacer(minLength: DesignTokens.Spacing.huge + 60)
                }
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.bottom, DesignTokens.Spacing.huge)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(palette.background)

            // Bottom install button
            if !showSuccess {
                VStack {
                    Spacer()
                    installButton
                }
            }

            if showSuccess {
                successOverlay
            }
        }
        .navigationTitle(pack.title)
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
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
        GlassCard(
            intensity: .medium,
            cornerRadius: DesignTokens.CornerRadius.xl,
            shadowRadius: 6
        ) {
            VStack(spacing: DesignTokens.Spacing.sm) {
                Text(pack.runicGlyph)
                    .font(.system(size: 48))
                    .foregroundStyle(palette.runeText)

                Text(pack.title)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(palette.textPrimary)

                Text("\(pack.quoteCount) quotes \u{00B7} \(pack.subtitle)")
                    .font(.subheadline)
                    .foregroundStyle(palette.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Description

    @ViewBuilder
    private var descriptionSection: some View {
        Text(pack.description)
            .font(.body)
            .foregroundStyle(palette.textSecondary)
    }

    // MARK: - Preview Section

    @ViewBuilder
    private var previewSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Preview")
                .font(.headline)
                .foregroundStyle(palette.textPrimary)

            ForEach(Array(pack.previewQuotes.enumerated()), id: \.offset) { index, quote in
                HStack(alignment: .top, spacing: DesignTokens.Spacing.sm) {
                    Text("\(index + 1)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(palette.accent)
                        .frame(width: 20, alignment: .trailing)

                    Text("\"\(quote)\"")
                        .font(.body)
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

    // MARK: - Install Button

    @ViewBuilder
    private var installButton: some View {
        VStack(spacing: 0) {
            // Gradient fade above button
            LinearGradient(
                colors: [palette.background.opacity(0), palette.background],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: DesignTokens.Spacing.xxl)

            VStack {
                if isInstalled {
                    GlassButton.secondary("Installed", icon: "checkmark") {}
                        .disabled(true)
                        .opacity(0.6)
                } else {
                    GlassButton.primary("Install Pack", icon: "arrow.down.circle") {
                        installPack()
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, DesignTokens.Spacing.xxl)
            .padding(.bottom, DesignTokens.Spacing.xl)
            .background(palette.background)
        }
    }

    // MARK: - Success Overlay

    @ViewBuilder
    private var successOverlay: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(palette.accent)

            Text("Pack Added")
                .font(.title.weight(.bold))
                .foregroundStyle(palette.textPrimary)

            Text("\(pack.quoteCount) quotes from \(pack.title) are now in your collection.")
                .font(.body)
                .foregroundStyle(palette.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignTokens.Spacing.xxl)

            Spacer()

            GlassButton.primary("Explore Pack", icon: nil, hapticTier: nil) {
                dismiss()
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, DesignTokens.Spacing.xxl)

            Spacer()
                .frame(height: DesignTokens.Spacing.huge)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(palette.background)
        .transition(.opacity)
    }

    // MARK: - Actions

    private func loadInstalledState() {
        do {
            let preferences = try UserPreferences.getOrCreate(in: modelContext)
            isInstalled = preferences.isPackInstalled(pack.id)
        } catch {
            isInstalled = false
        }
    }

    private func installPack() {
        do {
            let preferences = try UserPreferences.getOrCreate(in: modelContext)
            preferences.installPack(pack.id)
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
    }
}
