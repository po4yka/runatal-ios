//
//  CreateEditQuoteView.swift
//  RunicQuotes
//
//  Created by Claude on 12.03.26.
//

import SwiftData
import SwiftUI

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
        onSaved: ((UUID?) -> Void)? = nil,
    ) {
        self.mode = mode
        self.onSaved = onSaved
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        let palette = AppThemePalette.themed(self.runicTheme, for: self.colorScheme)

        ZStack {
            if self.viewModel.state.showSuccess, case .create = self.viewModel.mode {
                self.successOverlay(palette: palette)
            } else {
                self.formContent(palette: palette)
            }
        }
        .navigationTitle(self.viewModel.mode.navigationTitle)
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { self.dismiss() }
                        .foregroundStyle(palette.accent)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(self.viewModel.mode.saveButtonTitle) {
                        self.viewModel.save()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(palette.accent)
                    .disabled(self.viewModel.state.isSaving)
                }
            }
            .onChange(of: self.viewModel.state.showSuccess) { _, showSuccess in
                if showSuccess, case .edit = self.viewModel.mode {
                    self.onSaved?(nil)
                    self.dismiss()
                }
            }
    }

    // MARK: - Form Content

    private func formContent(palette: AppThemePalette) -> some View {
        LiquidContentScaffold(
            palette: palette,
            topPadding: DesignTokens.Spacing.md,
            spacing: DesignTokens.Spacing.xl,
            showBackgroundExtension: false,
        ) {
            self.quoteSection(palette: palette)
            self.attributionSection(palette: palette)
            self.collectionSection(palette: palette)
            self.runePreviewSection(palette: palette)
        }
    }

    // MARK: - Quote Section

    private func quoteSection(palette: AppThemePalette) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            self.sectionHeader("Quote", palette: palette)

            ContentPlate(
                palette: palette,
                tone: .secondary,
                cornerRadius: DesignTokens.CornerRadius.xl,
                shadowRadius: 0,
                contentPadding: DesignTokens.Spacing.md,
            ) {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    TextField(
                        "Enter your quote text...",
                        text: Binding(
                            get: { self.viewModel.state.quoteText },
                            set: { self.viewModel.updateQuoteText($0) },
                        ),
                        axis: .vertical,
                    )
                    .lineLimit(3 ... 8)
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

    private func attributionSection(palette: AppThemePalette) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            self.sectionHeader("Attribution", palette: palette)

            ContentPlate(
                palette: palette,
                tone: .secondary,
                cornerRadius: DesignTokens.CornerRadius.xl,
                shadowRadius: 0,
                contentPadding: 0,
            ) {
                VStack(spacing: 0) {
                    self.fieldRow(
                        label: "Author",
                        placeholder: "Required",
                        text: Binding(
                            get: { self.viewModel.state.author },
                            set: { self.viewModel.updateAuthor($0) },
                        ),
                        error: self.viewModel.validation.authorError,
                        palette: palette,
                    )

                    Divider()
                        .overlay(palette.separator)

                    self.fieldRow(
                        label: "Source",
                        placeholder: "Optional",
                        text: Binding(
                            get: { self.viewModel.state.source },
                            set: { self.viewModel.updateSource($0) },
                        ),
                        error: nil,
                        palette: palette,
                    )
                }
            }
        }
    }

    // MARK: - Collection Section

    private func collectionSection(palette: AppThemePalette) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            self.sectionHeader("Collection", palette: palette)

            ContentPlate(
                palette: palette,
                tone: .secondary,
                cornerRadius: DesignTokens.CornerRadius.xl,
                shadowRadius: 0,
                contentPadding: DesignTokens.Spacing.md,
            ) {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text("Add to Collection")
                        .font(DesignTokens.Typography.supportingBody)
                        .foregroundStyle(palette.textSecondary)

                    self.collectionChips(palette: palette)
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
                    let isSelected = self.viewModel.state.collection == collection
                    Button {
                        self.viewModel.updateCollection(collection)
                    } label: {
                        Text(collection.displayName)
                            .font(DesignTokens.Typography.controlLabel)
                            .foregroundStyle(isSelected ? palette.background : palette.textPrimary)
                            .padding(.horizontal, DesignTokens.Spacing.sm)
                            .padding(.vertical, DesignTokens.Spacing.xs)
                            .background(
                                Capsule()
                                    .fill(isSelected ? palette.accent : palette.surface),
                            )
                            .overlay(
                                Capsule()
                                    .strokeBorder(
                                        isSelected ? palette.accent : palette.separator,
                                        lineWidth: 1,
                                    ),
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Rune Preview Section

    private func runePreviewSection(palette: AppThemePalette) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            self.sectionHeader("Rune Preview", palette: palette)

            ContentPlate(
                palette: palette,
                tone: .secondary,
                cornerRadius: DesignTokens.CornerRadius.xl,
                shadowRadius: 0,
                contentPadding: DesignTokens.Spacing.md,
            ) {
                VStack(spacing: DesignTokens.Spacing.sm) {
                    if self.viewModel.state.runicPreview.isEmpty {
                        Text("Type a quote to see the runic preview")
                            .font(DesignTokens.Typography.supportingBody)
                            .foregroundStyle(palette.textTertiary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, DesignTokens.Spacing.xl)
                    } else {
                        Text(self.viewModel.state.runicPreview)
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

    private func successOverlay(palette: AppThemePalette) -> some View {
        Color.black.opacity(0.12)
            .ignoresSafeArea()
            .overlay {
                ContentPlate(
                    palette: palette,
                    tone: .hero,
                    cornerRadius: DesignTokens.CornerRadius.xxl,
                    shadowRadius: DesignTokens.Elevation.hero,
                    contentPadding: DesignTokens.Spacing.xl,
                ) {
                    VStack(spacing: DesignTokens.Spacing.lg) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(palette.accent)

                        Text("Quote Created")
                            .font(DesignTokens.Typography.pageTitle)
                            .foregroundStyle(palette.textPrimary)

                        Text("Your quote has been added to the \(self.viewModel.state.collection.displayName) collection and is ready to inspire runic wisdom.")
                            .font(DesignTokens.Typography.supportingBody)
                            .foregroundStyle(palette.textSecondary)
                            .multilineTextAlignment(.center)

                        Button {
                            self.onSaved?(self.viewModel.state.createdQuoteID)
                            self.dismiss()
                        } label: {
                            Text("View Quote")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(LiquidProminentButtonStyle(palette: palette, emphasized: true))

                        Button("Create another") {
                            self.viewModel.resetForNewQuote()
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

    private func sectionHeader(_ title: String, palette: AppThemePalette) -> some View {
        Text(title)
            .font(DesignTokens.Typography.cardTitle)
            .foregroundStyle(palette.textPrimary)
    }

    private func fieldRow(
        label: String,
        placeholder: String,
        text: Binding<String>,
        error: String?,
        palette: AppThemePalette,
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
            mode: .create,
        )
    }
    .modelContainer(for: [Quote.self, UserPreferences.self], inMemory: true)
}

#Preview("Edit") {
    let record = QuoteRecord(
        from: Quote(
            textLatin: "Not all those who wander are lost.",
            author: "J.R.R. Tolkien",
            collection: .tolkien,
        ),
    )
    NavigationStack {
        CreateEditQuoteView(
            viewModel: CreateEditQuoteViewModel.preview(mode: .edit(record)),
            mode: .edit(record),
        )
    }
    .modelContainer(for: [Quote.self, UserPreferences.self], inMemory: true)
}
