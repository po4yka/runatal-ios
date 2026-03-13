//
//  QuoteActionsSheet.swift
//  RunicQuotes
//
//  Created by Claude on 2026-03-12.
//

import SwiftUI

// MARK: - Quote Action

/// Actions available from the quote actions contextual sheet.
enum QuoteAction: Identifiable, Sendable {
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
        case .share: return "share"
        case .addToFavorites: return "addToFavorites"
        case .removeFromFavorites: return "removeFromFavorites"
        case .addToCollection: return "addToCollection"
        case .copyText: return "copyText"
        case .edit: return "edit"
        case .hide: return "hide"
        case .delete: return "delete"
        }
    }

    var title: String {
        switch self {
        case .share: return "Share Quote"
        case .addToFavorites: return "Add to Favorites"
        case .removeFromFavorites: return "Remove from Favorites"
        case .addToCollection: return "Add to Collection"
        case .copyText: return "Copy Text"
        case .edit: return "Edit Quote"
        case .hide: return "Hide Quote"
        case .delete: return "Delete Quote"
        }
    }

    var icon: String {
        switch self {
        case .share: return "square.and.arrow.up"
        case .addToFavorites: return "bookmark"
        case .removeFromFavorites: return "bookmark.slash"
        case .addToCollection: return "folder.badge.plus"
        case .copyText: return "doc.on.doc"
        case .edit: return "pencil"
        case .hide: return "eye.slash"
        case .delete: return "trash"
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
        .themed(runicTheme, for: colorScheme)
    }

    private var actions: [QuoteAction] {
        [
            .share,
            isSaved ? .removeFromFavorites : .addToFavorites,
            .addToCollection,
            .copyText,
            .edit,
            .hide,
            .delete
        ]
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(palette.textTertiary.opacity(0.3))
                .frame(width: 36, height: 5)
                .padding(.top, DesignTokens.Spacing.sm)
                .padding(.bottom, DesignTokens.Spacing.md)

            HeroHeader(
                eyebrow: "Actions",
                title: "Current passage",
                subtitle: "Choose how this quote should be handled.",
                palette: palette
            )
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.bottom, DesignTokens.Spacing.sm)

            ForEach(Array(actions.enumerated()), id: \.element.id) { index, action in
                actionRow(action)

                if index < actions.count - 1 && !action.isDestructive && actions[safe: index + 1]?.isDestructive != true {
                    Divider()
                        .background(palette.separator)
                        .padding(.leading, DesignTokens.Spacing.xxl + DesignTokens.Spacing.lg)
                }

                // Add extra spacing before destructive action
                if !action.isDestructive, actions[safe: index + 1]?.isDestructive == true {
                    Rectangle()
                        .fill(palette.separator.opacity(0.3))
                        .frame(height: 8)
                }
            }

            Spacer()
                .frame(height: DesignTokens.Spacing.md)
        }
        .background(palette.editorialSurface)
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(DesignTokens.CornerRadius.xl)
    }

    // MARK: - Action Row

    private func actionRow(_ action: QuoteAction) -> some View {
        Button {
            dismiss()
            onAction(action)
        } label: {
            HStack(spacing: DesignTokens.Spacing.md) {
                Image(systemName: action.icon)
                    .font(.body)
                    .frame(width: 18, height: 18)
                    .foregroundStyle(action.isDestructive ? palette.error : palette.textPrimary)

                Text(action.title)
                    .font(.body)
                    .foregroundStyle(action.isDestructive ? palette.error : palette.textPrimary)

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
