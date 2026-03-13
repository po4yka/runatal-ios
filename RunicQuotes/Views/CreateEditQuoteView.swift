//
//  CreateEditQuoteView.swift
//  RunicQuotes
//
//  Created by Claude on 2026-03-12.
//

import SwiftUI
import SwiftData

/// Form for creating or editing a quote, matching Figma Create & Edit page.
struct CreateEditQuoteView: View {
    // MARK: - Properties

    @StateObject private var viewModel: CreateEditQuoteViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    @State private var didInitialize = false

    private let mode: CreateEditMode
    private let onSaved: ((UUID?) -> Void)?

    // MARK: - Initialization

    init(mode: CreateEditMode = .create, onSaved: ((UUID?) -> Void)? = nil) {
        self.mode = mode
        self.onSaved = onSaved
        let container = ModelContainerHelper.createPlaceholderContainer()
        _viewModel = StateObject(wrappedValue: CreateEditQuoteViewModel(
            modelContext: ModelContext(container),
            mode: mode
        ))
    }

    // MARK: - Body

    var body: some View {
        let palette = AppThemePalette.adaptive(for: colorScheme)

        ZStack {
            palette.background.ignoresSafeArea()

            if viewModel.state.showSuccess, case .create = viewModel.mode {
                successOverlay(palette: palette)
            } else {
                formContent(palette: palette)
            }
        }
        .navigationTitle(viewModel.mode.navigationTitle)
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
                    .foregroundStyle(palette.accent)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(viewModel.mode.saveButtonTitle) {
                    viewModel.save()
                }
                .fontWeight(.semibold)
                .foregroundStyle(palette.accent)
                .disabled(viewModel.state.isSaving)
            }
        }
        .task {
            guard !didInitialize else { return }
            didInitialize = true
            viewModel.configureIfNeeded(modelContext: modelContext)
        }
        .onChange(of: viewModel.state.showSuccess) { _, showSuccess in
            if showSuccess, case .edit = viewModel.mode {
                onSaved?(nil)
                dismiss()
            }
        }
    }

    // MARK: - Form Content

    @ViewBuilder
    private func formContent(palette: AppThemePalette) -> some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.xl) {
                quoteSection(palette: palette)
                attributionSection(palette: palette)
                collectionSection(palette: palette)
                runePreviewSection(palette: palette)
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.top, DesignTokens.Spacing.md)
            .padding(.bottom, DesignTokens.Spacing.xxxl)
        }
    }

    // MARK: - Quote Section

    @ViewBuilder
    private func quoteSection(palette: AppThemePalette) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            sectionHeader("Quote", palette: palette)

            GlassCard(intensity: .light) {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    TextField(
                        "Enter your quote text...",
                        text: Binding(
                            get: { viewModel.state.quoteText },
                            set: { viewModel.updateQuoteText($0) }
                        ),
                        axis: .vertical
                    )
                    .lineLimit(3...8)
                    .font(.body)
                    .foregroundStyle(palette.textPrimary)
                    .tint(palette.accent)

                    if let error = viewModel.validation.quoteTextError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(palette.error)
                    }
                }
                .padding(DesignTokens.Spacing.md)
            }
        }
    }

    // MARK: - Attribution Section

    @ViewBuilder
    private func attributionSection(palette: AppThemePalette) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            sectionHeader("Attribution", palette: palette)

            GlassCard(intensity: .light) {
                VStack(spacing: 0) {
                    fieldRow(
                        label: "Author",
                        placeholder: "Required",
                        text: Binding(
                            get: { viewModel.state.author },
                            set: { viewModel.updateAuthor($0) }
                        ),
                        error: viewModel.validation.authorError,
                        palette: palette
                    )

                    Divider()
                        .overlay(palette.separator)

                    fieldRow(
                        label: "Source",
                        placeholder: "Optional",
                        text: Binding(
                            get: { viewModel.state.source },
                            set: { viewModel.updateSource($0) }
                        ),
                        error: nil,
                        palette: palette
                    )
                }
            }
        }
    }

    // MARK: - Collection Section

    @ViewBuilder
    private func collectionSection(palette: AppThemePalette) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            sectionHeader("Collection", palette: palette)

            GlassCard(intensity: .light) {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text("Add to Collection")
                        .font(.subheadline)
                        .foregroundStyle(palette.textSecondary)

                    collectionChips(palette: palette)
                }
                .padding(DesignTokens.Spacing.md)
            }
        }
    }

    @ViewBuilder
    private func collectionChips(palette: AppThemePalette) -> some View {
        let assignableCollections = QuoteCollection.allCases.filter { $0 != .all }

        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignTokens.Spacing.xs) {
                ForEach(assignableCollections) { collection in
                    let isSelected = viewModel.state.collection == collection
                    Button {
                        viewModel.updateCollection(collection)
                    } label: {
                        Text(collection.displayName)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(isSelected ? palette.background : palette.textPrimary)
                            .padding(.horizontal, DesignTokens.Spacing.sm)
                            .padding(.vertical, DesignTokens.Spacing.xs)
                            .background(
                                Capsule()
                                    .fill(isSelected ? palette.accent : palette.surface)
                            )
                            .overlay(
                                Capsule()
                                    .strokeBorder(
                                        isSelected ? palette.accent : palette.separator,
                                        lineWidth: 1
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Rune Preview Section

    @ViewBuilder
    private func runePreviewSection(palette: AppThemePalette) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            sectionHeader("Rune Preview", palette: palette)

            GlassCard(intensity: .medium) {
                VStack(spacing: DesignTokens.Spacing.sm) {
                    if viewModel.state.runicPreview.isEmpty {
                        Text("Type a quote to see the runic preview")
                            .font(.subheadline)
                            .foregroundStyle(palette.textTertiary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, DesignTokens.Spacing.xl)
                    } else {
                        Text(viewModel.state.runicPreview)
                            .font(.title2)
                            .foregroundStyle(palette.runeText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .lineLimit(4)
                    }
                }
                .padding(DesignTokens.Spacing.md)
            }
        }
    }

    // MARK: - Success Overlay

    @ViewBuilder
    private func successOverlay(palette: AppThemePalette) -> some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(palette.accent)

            Text("Quote Created")
                .font(.title.weight(.bold))
                .foregroundStyle(palette.textPrimary)

            Text("Your quote has been added to the \(viewModel.state.collection.displayName) collection and is ready to inspire runic wisdom.")
                .font(.body)
                .foregroundStyle(palette.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignTokens.Spacing.xxl)

            Spacer()

            VStack(spacing: DesignTokens.Spacing.md) {
                GlassButton.primary("View Quote", icon: nil, hapticTier: nil) {
                    onSaved?(viewModel.state.createdQuoteID)
                    dismiss()
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, DesignTokens.Spacing.xxl)

                Button("Create another") {
                    viewModel.resetForNewQuote()
                }
                .font(.body)
                .foregroundStyle(palette.accent)
            }

            Spacer()
                .frame(height: DesignTokens.Spacing.huge)
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func sectionHeader(_ title: String, palette: AppThemePalette) -> some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(palette.textPrimary)
    }

    @ViewBuilder
    private func fieldRow(
        label: String,
        placeholder: String,
        text: Binding<String>,
        error: String?,
        palette: AppThemePalette
    ) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(palette.textSecondary)
                    .frame(width: 70, alignment: .leading)

                TextField(placeholder, text: text)
                    .font(.body)
                    .foregroundStyle(palette.textPrimary)
                    .tint(palette.accent)
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.vertical, DesignTokens.Spacing.sm)

            if let error {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(palette.error)
                    .padding(.horizontal, DesignTokens.Spacing.md)
                    .padding(.bottom, DesignTokens.Spacing.xxs)
            }
        }
    }
}

// MARK: - Preview

#Preview("Create") {
    NavigationStack {
        CreateEditQuoteView(mode: .create)
    }
    .modelContainer(for: [Quote.self, UserPreferences.self], inMemory: true)
}

#Preview("Edit") {
    let record = QuoteRecord(
        from: Quote(
            textLatin: "Not all those who wander are lost.",
            author: "J.R.R. Tolkien",
            collection: .tolkien
        )
    )
    NavigationStack {
        CreateEditQuoteView(mode: .edit(record))
    }
    .modelContainer(for: [Quote.self, UserPreferences.self], inMemory: true)
}
