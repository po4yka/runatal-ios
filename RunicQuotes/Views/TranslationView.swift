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

struct TranslationView: View {
    @StateObject private var viewModel: TranslationViewModel
    @State private var didInitialize = false
    @State private var transientFeedback: TranslationFeedbackState?
    @State private var feedbackTask: Task<Void, Never>?
    @State private var showProvenanceSheet = false
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.runicTheme) private var runicTheme

    init(viewModel: TranslationViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        LiquidContentScaffold(
            palette: palette,
            topPadding: DesignTokens.Spacing.xl,
            spacing: DesignTokens.Spacing.xl,
            showBackgroundExtension: false
        ) {
            HeroHeader(
                eyebrow: "Translation",
                title: "Runic Studio",
                subtitle: "Shift between direct transliteration and a historically constrained translation path without leaving the reading flow.",
                meta: headerMeta,
                palette: palette
            )

            if let feedback = activeFeedback {
                FeedbackBanner(
                    palette: palette,
                    tone: feedback.tone,
                    title: feedback.title,
                    message: feedback.message
                )
            }

            TranslationComposerSectionView(
                state: viewModel.state,
                palette: palette,
                modeBinding: modeBinding,
                fidelityBinding: fidelityBinding,
                youngerVariantBinding: youngerVariantBinding,
                inputBinding: inputBinding,
                wordByWordBinding: wordByWordBinding,
                selectScript: viewModel.selectScript(_:)
            )

            TranslationResultSectionView(
                state: viewModel.state,
                palette: palette,
                copyAction: copyOutput,
                clearAction: viewModel.clearInput,
                saveAction: viewModel.saveToLibrary,
                openSourcesAction: viewModel.state.provenance.isEmpty ? nil : { showProvenanceSheet = true }
            )

            TranslationSupplementarySectionsView(
                state: viewModel.state,
                palette: palette
            )
        }
        .accessibilityIdentifier("translation_view")
        .task {
            guard !didInitialize else { return }
            didInitialize = true
            viewModel.onAppear()
        }
        .onDisappear {
            feedbackTask?.cancel()
        }
        .sheet(isPresented: $showProvenanceSheet) {
            TranslationProvenanceDetailSheet(provenance: viewModel.state.provenance)
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
    }

    private var palette: AppThemePalette {
        .themed(runicTheme, for: colorScheme)
    }

    private var headerMeta: [String] {
        [
            viewModel.state.translationMode.displayName,
            viewModel.state.selectedScript.displayName,
            viewModel.state.translationMode == .translate
                ? viewModel.state.selectedFidelity.displayName
                : "Direct"
        ]
    }

    private var activeFeedback: TranslationFeedbackState? {
        if let errorMessage = viewModel.state.errorMessage {
            return TranslationFeedbackState(
                tone: .error,
                title: "Translation unavailable",
                message: errorMessage
            )
        }

        if let transientFeedback {
            return transientFeedback
        }

        if let successMessage = viewModel.state.successMessage {
            return TranslationFeedbackState(
                tone: .success,
                title: "Saved",
                message: successMessage
            )
        }

        return nil
    }

    private var inputBinding: Binding<String> {
        Binding(
            get: { viewModel.state.inputText },
            set: { viewModel.updateInputText($0) }
        )
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

    private var wordByWordBinding: Binding<Bool> {
        Binding(
            get: { viewModel.state.isWordByWordEnabled },
            set: { viewModel.setWordByWordEnabled($0) }
        )
    }

    private func copyOutput() {
        guard !viewModel.state.outputText.isEmpty else { return }

        Haptics.trigger(.saveOrShare)
#if canImport(UIKit)
        UIPasteboard.general.string = viewModel.state.outputText
#endif
        showTransientFeedback(
            tone: .success,
            title: "Copied",
            message: "Runic output has been copied to the clipboard."
        )
    }

    private func showTransientFeedback(
        tone: FeedbackBanner.Tone,
        title: String,
        message: String
    ) {
        feedbackTask?.cancel()
        transientFeedback = TranslationFeedbackState(
            tone: tone,
            title: title,
            message: message
        )

        feedbackTask = Task {
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                transientFeedback = nil
            }
        }
    }
}

private struct TranslationFeedbackState {
    let tone: FeedbackBanner.Tone
    let title: String
    let message: String
}

#Preview {
    NavigationStack {
        TranslationView(viewModel: TranslationViewModel.preview())
            .modelContainer(ModelContainerHelper.createPlaceholderContainer())
    }
}
