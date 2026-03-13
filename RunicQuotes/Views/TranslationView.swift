//
//  TranslationView.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
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
    @State private var showAccuracyContext = false
    @State private var showProvenanceSheet = false
    @FocusState private var isInputFocused: Bool
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.runicTheme) private var runicTheme
    @EnvironmentObject private var featureDiscoveryController: FeatureDiscoveryController

    init(viewModel: TranslationViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        LiquidContentScaffold(
            palette: self.palette,
            topPadding: DesignTokens.Spacing.xl,
            spacing: DesignTokens.Spacing.xl,
            showBackgroundExtension: false,
        ) {
            HeroHeader(
                eyebrow: "Translation",
                title: "Runic Studio",
                subtitle: "Shift between direct transliteration and a historically constrained translation path without leaving the reading flow.",
                meta: self.headerMeta,
                palette: self.palette,
            )

            if let feedback = activeFeedback {
                FeedbackBanner(
                    palette: self.palette,
                    tone: feedback.tone,
                    title: feedback.title,
                    message: feedback.message,
                )
            }

            TranslationComposerSectionView(
                state: self.viewModel.state,
                palette: self.palette,
                tipRefreshID: self.featureDiscoveryController.refreshID,
                modeBinding: self.modeBinding,
                fidelityBinding: self.fidelityBinding,
                youngerVariantBinding: self.youngerVariantBinding,
                inputBinding: self.inputBinding,
                wordByWordBinding: self.wordByWordBinding,
                isInputFocused: self.$isInputFocused,
                selectScript: self.viewModel.selectScript(_:),
                openSourcesAction: self.viewModel.state.provenance.isEmpty ? nil : { self.showProvenanceSheet = true },
            )

            TranslationResultSectionView(
                state: self.viewModel.state,
                palette: self.palette,
                copyAction: self.copyOutput,
                clearAction: self.viewModel.clearInput,
                saveAction: self.viewModel.saveToLibrary,
                openSourcesAction: self.viewModel.state.provenance.isEmpty ? nil : { self.showProvenanceSheet = true },
            )

            TranslationSupplementarySectionsView(
                state: self.viewModel.state,
                palette: self.palette,
            )
        }
        .accessibilityIdentifier("translation_view")
        .task {
            guard !self.didInitialize else { return }
            self.didInitialize = true
            self.viewModel.onAppear()
        }
        .onDisappear {
            self.feedbackTask?.cancel()
        }
        .onChange(of: self.viewModel.state.translationMode) { _, _ in
            self.isInputFocused = false
        }
        .sheet(isPresented: self.$showProvenanceSheet) {
            TranslationProvenanceDetailSheet(provenance: self.viewModel.state.provenance)
        }
        .navigationDestination(isPresented: self.$showAccuracyContext) {
            TranslationAccuracyContextView()
        }
        .navigationTitle(String(localized: "translation.nav.title"))
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        self.recordTranslationMethodExploration()
                        self.showAccuracyContext = true
                    } label: {
                        Label(String(localized: "translation.accuracy.title"), systemImage: "info.circle")
                            .labelStyle(.iconOnly)
                    }
                    .accessibilityIdentifier("translation_accuracy_button")
                }
            }
    }

    private var palette: AppThemePalette {
        .themed(self.runicTheme, for: self.colorScheme)
    }

    private var headerMeta: [String] {
        [
            self.viewModel.state.translationMode.displayName,
            self.viewModel.state.selectedScript.displayName,
            self.viewModel.state.translationMode == .translate
                ? self.viewModel.state.selectedFidelity.displayName
                : "Direct",
        ]
    }

    private var activeFeedback: TranslationFeedbackState? {
        if let errorMessage = viewModel.state.errorMessage {
            return TranslationFeedbackState(
                tone: .error,
                title: "Translation unavailable",
                message: errorMessage,
            )
        }

        if let transientFeedback {
            return transientFeedback
        }

        if let successMessage = viewModel.state.successMessage {
            return TranslationFeedbackState(
                tone: .success,
                title: "Saved",
                message: successMessage,
            )
        }

        return nil
    }

    private var inputBinding: Binding<String> {
        Binding(
            get: { self.viewModel.state.inputText },
            set: { self.viewModel.updateInputText($0) },
        )
    }

    private var modeBinding: Binding<TranslationMode> {
        Binding(
            get: { self.viewModel.state.translationMode },
            set: {
                self.viewModel.selectMode($0)
                self.recordTranslationMethodExploration()
            },
        )
    }

    private var fidelityBinding: Binding<TranslationFidelity> {
        Binding(
            get: { self.viewModel.state.selectedFidelity },
            set: {
                self.viewModel.selectFidelity($0)
                self.recordTranslationMethodExploration()
            },
        )
    }

    private var youngerVariantBinding: Binding<YoungerFutharkVariant> {
        Binding(
            get: { self.viewModel.state.selectedYoungerVariant },
            set: { self.viewModel.selectYoungerVariant($0) },
        )
    }

    private var wordByWordBinding: Binding<Bool> {
        Binding(
            get: { self.viewModel.state.isWordByWordEnabled },
            set: { self.viewModel.setWordByWordEnabled($0) },
        )
    }

    private func copyOutput() {
        guard !self.viewModel.state.outputText.isEmpty else { return }

        Haptics.trigger(.saveOrShare)
        #if canImport(UIKit)
            UIPasteboard.general.string = self.viewModel.state.outputText
        #endif
        self.showTransientFeedback(
            tone: .success,
            title: "Copied",
            message: "Runic output has been copied to the clipboard.",
        )
    }

    private func showTransientFeedback(
        tone: FeedbackBanner.Tone,
        title: String,
        message: String,
    ) {
        self.feedbackTask?.cancel()
        self.transientFeedback = TranslationFeedbackState(
            tone: tone,
            title: title,
            message: message,
        )

        self.feedbackTask = Task {
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                self.transientFeedback = nil
            }
        }
    }

    private func recordTranslationMethodExploration() {
        FeatureDiscoveryEvents.translationAdjustedMethod.sendDonation()
        TranslationMethodTip().invalidate(reason: .actionPerformed)
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
    .environmentObject(FeatureDiscoveryController.preview())
}
