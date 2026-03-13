//
//  QuoteActionsSheet.swift
//  RunicQuotes
//
//  Created by Claude on 12.03.26.
//

import SwiftUI

// MARK: - Quote Action

/// Actions available from the quote actions contextual sheet.
enum QuoteAction: Identifiable {
    case share
    case addToFavorites
    case removeFromFavorites
    case addToCollection
    case copyText
    case edit
    case hide
    case delete

    var id: String {
        switch self {
        case .share: "share"
        case .addToFavorites: "addToFavorites"
        case .removeFromFavorites: "removeFromFavorites"
        case .addToCollection: "addToCollection"
        case .copyText: "copyText"
        case .edit: "edit"
        case .hide: "hide"
        case .delete: "delete"
        }
    }

    var title: String {
        switch self {
        case .share: "Share Quote"
        case .addToFavorites: "Add to Favorites"
        case .removeFromFavorites: "Remove from Favorites"
        case .addToCollection: "Add to Collection"
        case .copyText: "Copy Text"
        case .edit: "Edit Quote"
        case .hide: "Hide Quote"
        case .delete: "Delete Quote"
        }
    }

    var icon: String {
        switch self {
        case .share: "square.and.arrow.up"
        case .addToFavorites: "bookmark"
        case .removeFromFavorites: "bookmark.slash"
        case .addToCollection: "folder.badge.plus"
        case .copyText: "doc.on.doc"
        case .edit: "pencil"
        case .hide: "eye.slash"
        case .delete: "trash"
        }
    }

    var isDestructive: Bool {
        self == .delete
    }
}

// MARK: - QuoteActionsSheet

/// Contextual action sheet for quote interactions, matching Figma Dialogs & Overlays design.
struct QuoteActionsSheet: View {
    // MARK: - Properties

    let isSaved: Bool
    let onAction: (QuoteAction) -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.runicTheme) private var runicTheme

    private var palette: AppThemePalette {
        .themed(self.runicTheme, for: self.colorScheme)
    }

    private var actions: [QuoteAction] {
        [
            .share,
            self.isSaved ? .removeFromFavorites : .addToFavorites,
            .addToCollection,
            .copyText,
            .edit,
            .hide,
            .delete,
        ]
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(self.palette.textTertiary.opacity(0.3))
                .frame(width: 36, height: 5)
                .padding(.top, DesignTokens.Spacing.sm)
                .padding(.bottom, DesignTokens.Spacing.md)

            HeroHeader(
                eyebrow: "Actions",
                title: "Current passage",
                subtitle: "Choose how this quote should be handled.",
                palette: self.palette,
            )
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.bottom, DesignTokens.Spacing.sm)

            ForEach(Array(self.actions.enumerated()), id: \.element.id) { index, action in
                self.actionRow(action)

                if index < self.actions.count - 1 && !action.isDestructive && self.actions[safe: index + 1]?.isDestructive != true {
                    Divider()
                        .background(self.palette.separator)
                        .padding(.leading, DesignTokens.Spacing.xxl + DesignTokens.Spacing.lg)
                }

                // Add extra spacing before destructive action
                if !action.isDestructive, self.actions[safe: index + 1]?.isDestructive == true {
                    Rectangle()
                        .fill(self.palette.separator.opacity(0.3))
                        .frame(height: 8)
                }
            }

            Spacer()
                .frame(height: DesignTokens.Spacing.md)
        }
        .background(self.palette.editorialSurface)
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(DesignTokens.CornerRadius.xl)
    }

    // MARK: - Action Row

    private func actionRow(_ action: QuoteAction) -> some View {
        Button {
            self.dismiss()
            self.onAction(action)
        } label: {
            HStack(spacing: DesignTokens.Spacing.md) {
                Image(systemName: action.icon)
                    .font(.body)
                    .frame(width: 18, height: 18)
                    .foregroundStyle(action.isDestructive ? self.palette.error : self.palette.textPrimary)

                Text(action.title)
                    .font(.body)
                    .foregroundStyle(action.isDestructive ? self.palette.error : self.palette.textPrimary)

                Spacer()
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .frame(height: 46)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(action.title)
        .accessibilityIdentifier("quote_action_\(action.id)")
    }
}

// MARK: - Safe Array Subscript

private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Preview

#Preview("Quote Actions - Not Saved") {
    Color.black
        .sheet(isPresented: .constant(true)) {
            QuoteActionsSheet(isSaved: false) { _ in
            }
        }
}

#Preview("Quote Actions - Saved") {
    Color.black
        .sheet(isPresented: .constant(true)) {
            QuoteActionsSheet(isSaved: true) { _ in
            }
        }
}
