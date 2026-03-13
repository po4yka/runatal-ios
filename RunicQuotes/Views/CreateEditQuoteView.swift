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
    @Environment(\.runicTheme) private var runicTheme

    private let mode: CreateEditMode
    private let onSaved: ((UUID?) -> Void)?

    // MARK: - Initialization

    init(
        viewModel: CreateEditQuoteViewModel,
        mode: CreateEditMode = .create,
        onSaved: ((UUID?) -> Void)? = nil
    ) {
        self.mode = mode
        self.onSaved = onSaved
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        let palette = AppThemePalette.themed(runicTheme, for: colorScheme)

        ZStack {
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
        LiquidContentScaffold(
            palette: palette,
            topPadding: DesignTokens.Spacing.md,
            spacing: DesignTokens.Spacing.xl,
            showBackgroundExtension: false
        ) {
            quoteSection(palette: palette)
            attributionSection(palette: palette)
            collectionSection(palette: palette)
            runePreviewSection(palette: palette)
        }
    }

    // MARK: - Quote Section

    @ViewBuilder
    private func quoteSection(palette: AppThemePalette) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            sectionHeader("Quote", palette: palette)

            ContentPlate(
                palette: palette,
                tone: .secondary,
                cornerRadius: DesignTokens.CornerRadius.xl,
                shadowRadius: 0,
                contentPadding: DesignTokens.Spacing.md
            ) {
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
                            .font(DesignTokens.Typography.listMeta)
                            .foregroundStyle(palette.error)
                    }
                }
            }
        }
    }

    // MARK: - Attribution Section

    @ViewBuilder
    private func attributionSection(palette: AppThemePalette) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            sectionHeader("Attribution", palette: palette)

            ContentPlate(
                palette: palette,
                tone: .secondary,
                cornerRadius: DesignTokens.CornerRadius.xl,
                shadowRadius: 0,
                contentPadding: 0
            ) {
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

            ContentPlate(
                palette: palette,
                tone: .secondary,
                cornerRadius: DesignTokens.CornerRadius.xl,
                shadowRadius: 0,
                contentPadding: DesignTokens.Spacing.md
            ) {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text("Add to Collection")
                        .font(DesignTokens.Typography.supportingBody)
                        .foregroundStyle(palette.textSecondary)

                    collectionChips(palette: palette)
                }
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
                            .font(DesignTokens.Typography.controlLabel)
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

            ContentPlate(
                palette: palette,
                tone: .secondary,
                cornerRadius: DesignTokens.CornerRadius.xl,
                shadowRadius: 0,
                contentPadding: DesignTokens.Spacing.md
            ) {
                VStack(spacing: DesignTokens.Spacing.sm) {
                    if viewModel.state.runicPreview.isEmpty {
                        Text("Type a quote to see the runic preview")
                            .font(DesignTokens.Typography.supportingBody)
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
            }
        }
    }

    // MARK: - Success Overlay

    @ViewBuilder
    private func successOverlay(palette: AppThemePalette) -> some View {
        Color.black.opacity(0.12)
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
                            .font(.system(size: 56))
                            .foregroundStyle(palette.accent)

                        Text("Quote Created")
                            .font(DesignTokens.Typography.pageTitle)
                            .foregroundStyle(palette.textPrimary)

                        Text("Your quote has been added to the \(viewModel.state.collection.displayName) collection and is ready to inspire runic wisdom.")
                            .font(DesignTokens.Typography.supportingBody)
                            .foregroundStyle(palette.textSecondary)
                            .multilineTextAlignment(.center)

                        Button {
                            onSaved?(viewModel.state.createdQuoteID)
                            dismiss()
                        } label: {
                            Text("View Quote")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(LiquidProminentButtonStyle(palette: palette, emphasized: true))

                        Button("Create another") {
                            viewModel.resetForNewQuote()
                        }
                        .font(DesignTokens.Typography.controlLabel)
                        .foregroundStyle(palette.accent)
                    }
                    .frame(maxWidth: 360)
                }
                .padding(DesignTokens.Spacing.xl)
            }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func sectionHeader(_ title: String, palette: AppThemePalette) -> some View {
        Text(title)
            .font(DesignTokens.Typography.cardTitle)
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
                    .font(DesignTokens.Typography.supportingBody)
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
                    .font(DesignTokens.Typography.listMeta)
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
        CreateEditQuoteView(
            viewModel: CreateEditQuoteViewModel.preview(mode: .create),
            mode: .create
        )
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
        CreateEditQuoteView(
            viewModel: CreateEditQuoteViewModel.preview(mode: .edit(record)),
            mode: .edit(record)
        )
    }
    .modelContainer(for: [Quote.self, UserPreferences.self], inMemory: true)
}
