//
//  TranslationView.swift
//  RunicQuotes
//
//  Created by Codex on 2026-03-13.
//

import SwiftData
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// swiftlint:disable type_body_length
struct TranslationView: View {
    @StateObject private var viewModel: TranslationViewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.runicTheme) private var runicTheme
    @Environment(\.dismiss) private var dismiss
    @State private var didInitialize = false

    init() {
        let placeholderContainer = ModelContainerHelper.createPlaceholderContainer()
        _viewModel = StateObject(
            wrappedValue: TranslationViewModel(
                modelContext: ModelContext(placeholderContainer)
            )
        )
    }

    var body: some View {
        ScreenScaffold(palette: palette) {
            VStack(spacing: DesignTokens.Spacing.xl) {
                HeroHeader(
                    eyebrow: "Translation",
                    title: "Runic Studio",
                    subtitle: "Switch between direct transliteration and the structured historical translation pipeline.",
                    meta: [
                        viewModel.state.translationMode.displayName,
                        viewModel.state.selectedScript.displayName,
                        viewModel.state.translationMode == .translate ? viewModel.state.selectedFidelity.displayName : "Direct"
                    ],
                    palette: palette
                )

                inputCard
                outputCard

                if viewModel.state.isWordByWordEnabled, !viewModel.state.tokenBreakdown.isEmpty {
                    breakdownCard
                }

                if viewModel.state.translationMode == .translate {
                    if viewModel.state.normalizedForm != nil || viewModel.state.diplomaticForm != nil {
                        layersCard
                    }

                    if !viewModel.state.notes.isEmpty || viewModel.state.resolutionStatus != nil {
                        statusCard
                    }

                    if !viewModel.state.provenance.isEmpty {
                        provenanceCard
                    }
                }
            }
        }
        .accessibilityIdentifier("translation_view")
        .task {
            guard !didInitialize else { return }
            didInitialize = true
            viewModel.configureIfNeeded(modelContext: modelContext)
            viewModel.onAppear()
        }
        .navigationTitle(String(localized: "translation.nav.title"))
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink {
                    TranslationAccuracyContextView()
                } label: {
                    Label(String(localized: "translation.accuracy.title"), systemImage: "info.circle")
                        .labelStyle(.iconOnly)
                }
                .accessibilityIdentifier("translation_accuracy_button")
            }
        }
        .overlay(alignment: .bottom) {
            if let message = viewModel.state.successMessage {
                successBanner(message)
                    .padding(.bottom, DesignTokens.Spacing.lg)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    private var palette: AppThemePalette {
        .themed(runicTheme, for: colorScheme)
    }

    private var inputBinding: Binding<String> {
        Binding(
            get: { viewModel.state.inputText },
            set: { viewModel.updateInputText($0) }
        )
    }

    private var inputCard: some View {
        EditorialCard(palette: palette, tone: .hero) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                Picker("Mode", selection: modeBinding) {
                    ForEach(TranslationMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                GlassScriptSelector(
                    selectedScript: Binding(
                        get: { viewModel.state.selectedScript },
                        set: { viewModel.selectScript($0) }
                    )
                )

                if viewModel.state.translationMode == .translate {
                    Picker("Fidelity", selection: fidelityBinding) {
                        ForEach(TranslationFidelity.allCases) { fidelity in
                            Text(fidelity.displayName).tag(fidelity)
                        }
                    }
                    .pickerStyle(.segmented)

                    if viewModel.state.selectedScript == .younger {
                        Picker("Variant", selection: youngerVariantBinding) {
                            ForEach(YoungerFutharkVariant.allCases) { variant in
                                Text(variant.displayName).tag(variant)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text("Source Text")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(palette.textPrimary)

                    TextEditor(text: inputBinding)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 140)
                        .padding(DesignTokens.Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                                .fill(palette.editorialInset)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                                .strokeBorder(palette.cardStroke, lineWidth: DesignTokens.Stroke.hairline)
                        )
                        .accessibilityIdentifier("translation_input_editor")

                    HStack {
                        Text("\(viewModel.state.remainingCharacters) characters left")
                            .font(DesignTokens.Typography.metadata)
                            .foregroundStyle(palette.textTertiary)

                        Spacer()

                        Button(viewModel.state.isWordByWordEnabled ? "Hide Breakdown" : "Word by Word") {
                            viewModel.toggleWordByWordMode()
                        }
                        .font(DesignTokens.Typography.metadata.weight(.semibold))
                        .foregroundStyle(palette.accent)
                        .accessibilityIdentifier("translation_word_by_word_button")
                    }
                }
            }
        }
    }

    private var outputCard: some View {
        EditorialCard(palette: palette, tone: .primary) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                        Text("Runic Output")
                            .font(DesignTokens.Typography.cardTitle)
                            .foregroundStyle(palette.textPrimary)
                        Text(viewModel.state.translationMode == .translate ? "Structured glyph layer" : "Direct transliteration")
                            .font(DesignTokens.Typography.metadata)
                            .foregroundStyle(palette.textSecondary)
                    }

                    Spacer()

                    if let resolutionStatus = viewModel.state.resolutionStatus {
                        Text(resolutionStatus.displayName)
                            .font(DesignTokens.Typography.metadata.weight(.semibold))
                            .foregroundStyle(palette.accent)
                    }
                }

                if viewModel.state.outputText.isEmpty {
                    Text("Enter up to 280 characters to generate runic output.")
                        .font(DesignTokens.Typography.callout)
                        .foregroundStyle(palette.textSecondary)
                        .accessibilityIdentifier("translation_output_text")
                } else {
                    Text(viewModel.state.outputText)
                        .runicTextStyle(
                            script: viewModel.state.selectedScript,
                            font: viewModel.state.selectedFont,
                            style: .title2,
                            minSize: 28,
                            maxSize: 52
                        )
                        .foregroundStyle(palette.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                        .accessibilityIdentifier("translation_output_text")
                }

                if let errorMessage = viewModel.state.errorMessage {
                    Text(errorMessage)
                        .font(DesignTokens.Typography.metadata)
                        .foregroundStyle(.red)
                }

                if let fallbackSuggestion = viewModel.state.fallbackSuggestion {
                    Text(fallbackSuggestion)
                        .font(DesignTokens.Typography.metadata)
                        .foregroundStyle(palette.textSecondary)
                }

                HStack(spacing: DesignTokens.Spacing.md) {
                    actionButton("Copy", icon: "doc.on.doc") {
                        copyOutput()
                    }
                    .accessibilityIdentifier("translation_copy_button")
                    .disabled(viewModel.state.outputText.isEmpty)

                    actionButton("Clear", icon: "xmark.circle") {
                        viewModel.clearInput()
                    }
                    .accessibilityIdentifier("translation_clear_button")

                    actionButton(viewModel.state.translationMode == .translate ? "Save Translation" : "Save", icon: "square.and.arrow.down") {
                        viewModel.saveToLibrary()
                    }
                    .accessibilityIdentifier("translation_save_button")
                    .disabled(viewModel.state.isInputEmpty || viewModel.state.isSaving)
                }
            }
        }
        .accessibilityIdentifier("translation_output_card")
    }

    private var layersCard: some View {
        EditorialCard(palette: palette, tone: .secondary) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                Text("Language Layers")
                    .font(DesignTokens.Typography.cardTitle)
                    .foregroundStyle(palette.textPrimary)

                if let normalized = viewModel.state.normalizedForm {
                    layerRow(title: "Normalized", value: normalized)
                }

                if let diplomatic = viewModel.state.diplomaticForm {
                    layerRow(title: "Diplomatic", value: diplomatic)
                }
            }
        }
    }

    private var statusCard: some View {
        EditorialCard(palette: palette, tone: .secondary) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                if let derivationKind = viewModel.state.derivationKind {
                    layerRow(title: "Derivation", value: derivationKind.displayName)
                }

                if !viewModel.state.notes.isEmpty {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                        Text("Notes")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(palette.textPrimary)
                        ForEach(viewModel.state.notes, id: \.self) { note in
                            Text(note)
                                .font(DesignTokens.Typography.metadata)
                                .foregroundStyle(palette.textSecondary)
                        }
                    }
                }

                if !viewModel.state.unresolvedTokens.isEmpty {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                        Text("Unresolved Tokens")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(palette.textPrimary)
                        Text(viewModel.state.unresolvedTokens.joined(separator: ", "))
                            .font(DesignTokens.Typography.metadata)
                            .foregroundStyle(palette.textSecondary)
                    }
                }
            }
        }
    }

    private var provenanceCard: some View {
        EditorialCard(palette: palette, tone: .secondary) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                Text("Provenance")
                    .font(DesignTokens.Typography.cardTitle)
                    .foregroundStyle(palette.textPrimary)

                ForEach(viewModel.state.provenance, id: \.self) { entry in
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                        HStack {
                            Text(entry.label)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(palette.textPrimary)
                            Spacer()
                            Text(entry.license)
                                .font(DesignTokens.Typography.metadata)
                                .foregroundStyle(palette.textTertiary)
                        }

                        Text(entry.role)
                            .font(DesignTokens.Typography.metadata)
                            .foregroundStyle(palette.textSecondary)

                        if let detail = entry.detail {
                            Text(detail)
                                .font(DesignTokens.Typography.metadata)
                                .foregroundStyle(palette.textTertiary)
                        }

                        if let url = entry.url, let resolvedURL = URL(string: url) {
                            Link(destination: resolvedURL) {
                                Text(url)
                                    .font(DesignTokens.Typography.metadata)
                                    .foregroundStyle(palette.accent)
                                    .lineLimit(1)
                            }
                        }
                    }
                    .padding(.vertical, DesignTokens.Spacing.xxs)
                }
            }
        }
    }

    private var breakdownCard: some View {
        EditorialCard(palette: palette, tone: .secondary) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                Text(viewModel.state.translationMode == .translate ? "Token Breakdown" : "Word-by-Word")
                    .font(DesignTokens.Typography.cardTitle)
                    .foregroundStyle(palette.textPrimary)

                ForEach(viewModel.state.tokenBreakdown) { token in
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                        HStack {
                            Text(token.sourceToken)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(palette.textPrimary)
                            Spacer()
                            if viewModel.state.translationMode == .translate {
                                Text(token.resolutionStatus.displayName)
                                    .font(DesignTokens.Typography.metadata)
                                    .foregroundStyle(palette.textTertiary)
                            }
                        }

                        if viewModel.state.translationMode == .translate {
                            Text("Normalized: \(token.normalizedToken)")
                                .font(DesignTokens.Typography.metadata)
                                .foregroundStyle(palette.textSecondary)
                            Text("Diplomatic: \(token.diplomaticToken)")
                                .font(DesignTokens.Typography.metadata)
                                .foregroundStyle(palette.textSecondary)
                        }

                        Text(token.glyphToken)
                            .runicTextStyle(
                                script: viewModel.state.selectedScript,
                                font: viewModel.state.selectedFont,
                                style: .title3,
                                minSize: 20,
                                maxSize: 40
                            )
                            .foregroundStyle(palette.textPrimary)
                    }
                    .padding(.vertical, DesignTokens.Spacing.xxs)
                }
            }
        }
    }

    private var modeBinding: Binding<TranslationMode> {
        Binding(
            get: { viewModel.state.translationMode },
            set: { viewModel.selectMode($0) }
        )
    }

    private var fidelityBinding: Binding<TranslationFidelity> {
        Binding(
            get: { viewModel.state.selectedFidelity },
            set: { viewModel.selectFidelity($0) }
        )
    }

    private var youngerVariantBinding: Binding<YoungerFutharkVariant> {
        Binding(
            get: { viewModel.state.selectedYoungerVariant },
            set: { viewModel.selectYoungerVariant($0) }
        )
    }

    private func layerRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(palette.textPrimary)
            Text(value)
                .font(DesignTokens.Typography.callout)
                .foregroundStyle(palette.textSecondary)
                .textSelection(.enabled)
        }
    }

    private func actionButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(palette.accent)
    }

    private func copyOutput() {
        Haptics.trigger(.saveOrShare)
#if canImport(UIKit)
        UIPasteboard.general.string = viewModel.state.outputText
#endif
    }

    private func successBanner(_ message: String) -> some View {
        Text(message)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.vertical, DesignTokens.Spacing.sm)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.8))
            )
    }
}
// swiftlint:enable type_body_length

#Preview {
    NavigationStack {
        TranslationView()
            .modelContainer(ModelContainerHelper.createPlaceholderContainer())
    }
}
