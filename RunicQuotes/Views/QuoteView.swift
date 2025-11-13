//
//  QuoteView.swift
//  RunicQuotes
//
//  Created by Claude on 2025-11-15.
//

import SwiftUI

/// Main view for displaying runic quotes
struct QuoteView: View {
    // MARK: - Properties

    @StateObject private var viewModel: QuoteViewModel
    @Environment(\.modelContext) private var modelContext

    // MARK: - Initialization

    init() {
        // Initialize with a placeholder - will be replaced in onAppear
        _viewModel = StateObject(wrappedValue: QuoteViewModel(
            modelContext: ModelContext(
                try! ModelContainer(for: Quote.self, UserPreferences.self)
            )
        ))
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Liquid glass background
            backgroundGradient

            // Content
            if viewModel.state.isLoading {
                loadingView
            } else if let error = viewModel.state.errorMessage {
                errorView(error)
            } else {
                quoteContentView
            }
        }
        .task {
            // Reinitialize viewModel with correct context
            let vm = QuoteViewModel(modelContext: modelContext)
            _viewModel.wrappedValue = vm
            viewModel.onAppear()
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                .pureBlack,
                .darkGray1,
                .darkGray2,
                .darkGray1,
                .pureBlack
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .tint(.white)
                .scaleEffect(1.5)
                .accessibilityLabel("Loading")
                .accessibilityIdentifier("quote_loading_indicator")

            Text("Loading quote...")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Loading quote")
        .accessibilityIdentifier("quote_loading_view")
    }

    // MARK: - Error View

    private func errorView(_ message: String) -> some View {
        GlassCard {
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.largeTitle)
                    .foregroundColor(.red.opacity(0.8))
                    .accessibilityLabel("Error")

                Text("Error")
                    .font(.headline)
                    .foregroundColor(.white)

                Text(message)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)

                GlassButton.primary("Try Again", icon: "arrow.clockwise") {
                    viewModel.refresh()
                }
                .accessibilityLabel("Retry loading quote")
                .accessibilityHint("Double tap to try loading the quote again")
                .accessibilityIdentifier("quote_retry_button")
            }
            .padding()
        }
        .padding()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("quote_error_view")
    }

    // MARK: - Quote Content

    private var quoteContentView: some View {
        ScrollView {
            VStack(spacing: 30) {
                Spacer()
                    .frame(height: 20)

                // Script selector
                GlassScriptSelector(
                    selectedScript: Binding(
                        get: { viewModel.state.currentScript },
                        set: { viewModel.onScriptChanged($0) }
                    )
                )
                .padding(.horizontal)
                .accessibilityLabel("Runic script selector")
                .accessibilityValue(viewModel.state.currentScript.rawValue)
                .accessibilityHint("Select which runic script to display")
                .accessibilityIdentifier("quote_script_selector")

                // Quote card
                quoteCard

                // Action buttons
                actionButtons

                Spacer()
            }
        }
    }

    // MARK: - Quote Card

    private var quoteCard: some View {
        GlassCard.heavy {
            VStack(spacing: 24) {
                // Runic text
                Text(viewModel.state.runicText)
                    .runicTextStyle(
                        script: viewModel.state.currentScript,
                        font: viewModel.state.currentFont,
                        style: .title,
                        minSize: 24,
                        maxSize: 48
                    )
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(8)
                    .padding()
                    .accessibilityLabel("Runic text")
                    .accessibilityValue(viewModel.state.runicText)
                    .accessibilityHint("The quote displayed in \(viewModel.state.currentScript.rawValue)")

                Divider()
                    .background(
                        LinearGradient(
                            colors: [
                                .clear,
                                .white.opacity(0.3),
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .accessibilityHidden(true)

                // Latin text
                Text(viewModel.state.latinText)
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .accessibilityLabel("Quote")
                    .accessibilityValue(viewModel.state.latinText)

                // Author
                Text("— \(viewModel.state.author)")
                    .font(.callout)
                    .foregroundColor(.white.opacity(0.7))
                    .italic()
                    .accessibilityLabel("Author")
                    .accessibilityValue(viewModel.state.author)
            }
        }
        .padding(.horizontal)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("quote_card")

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 16) {
            // Refresh quote button
            GlassButton.primary("Next Quote", icon: "arrow.forward.circle.fill") {
                viewModel.onNextQuoteTapped()
            }
            .accessibilityLabel("Next quote")
            .accessibilityHint("Double tap to load the next quote")
            .accessibilityIdentifier("quote_next_button")

            // Shuffle button
            GlassButton("Shuffle", icon: "shuffle") {
                viewModel.onNextQuoteTapped()
            }
            .accessibilityLabel("Random quote")
            .accessibilityHint("Double tap to load a random quote")
            .accessibilityIdentifier("quote_shuffle_button")
        }
        .padding(.horizontal)
    }
}

// MARK: - Preview

#Preview {
    QuoteView()
        .modelContainer(for: [Quote.self, UserPreferences.self], inMemory: true)
}

#Preview("With Sample Data") {
    let container = try! ModelContainer(
        for: Quote.self, UserPreferences.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    // Add sample quote
    let quote = Quote(
        textLatin: "Not all those who wander are lost.",
        author: "J.R.R. Tolkien"
    )
    quote.runicElder = "ᚾᛟᛏ ᚨᛚᛚ ᚦᛟᛋᛖ ᚹᚺᛟ ᚹᚨᚾᛞᛖᚱ ᚨᚱᛖ ᛚᛟᛋᛏ"
    container.mainContext.insert(quote)

    return QuoteView()
        .modelContainer(container)
}
