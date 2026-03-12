//
//  NotificationCenterView.swift
//  RunicQuotes
//
//  Created by Claude on 2026-03-12.
//

import SwiftUI

// MARK: - Notification Item

/// Represents a single in-app notification.
struct NotificationItem: Identifiable, Sendable {
    let id: UUID
    let title: String
    let body: String
    let timestamp: String
    var isRead: Bool

    static var samples: [NotificationItem] {
        [
            NotificationItem(
                id: UUID(),
                title: "Daily Quote Ready",
                body: "Your new quote of the day is waiting.",
                timestamp: "Now",
                isRead: false
            ),
            NotificationItem(
                id: UUID(),
                title: "Streak Reminder",
                body: "You have a 12-day streak. Don't break it!",
                timestamp: "2h ago",
                isRead: false
            ),
            NotificationItem(
                id: UUID(),
                title: "New Pack Available",
                body: "Havamal Selections -- 32 quotes from Norse wisdom.",
                timestamp: "Yesterday",
                isRead: true
            ),
            NotificationItem(
                id: UUID(),
                title: "Weekly Summary",
                body: "You read 14 quotes this week. Nice pace.",
                timestamp: "3 days ago",
                isRead: true
            ),
        ]
    }
}

// MARK: - NotificationCenterView

/// In-app notification inbox matching the Figma Notification Center design.
struct NotificationCenterView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var notifications: [NotificationItem] = NotificationItem.samples

    private var palette: AppThemePalette {
        .adaptive(for: colorScheme)
    }

    private var hasUnread: Bool {
        notifications.contains { !$0.isRead }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            palette.background.ignoresSafeArea()

            if notifications.isEmpty {
                emptyState
            } else {
                notificationList
            }
        }
        .navigationTitle("Notifications")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if hasUnread {
                    Button("Mark All Read") {
                        markAllRead()
                    }
                    .font(.subheadline)
                    .foregroundStyle(palette.accent)
                }
            }
        }
    }

    // MARK: - Notification List

    private var notificationList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(notifications.enumerated()), id: \.element.id) { index, notification in
                    notificationRow(notification)

                    if index < notifications.count - 1 {
                        palette.separator
                            .frame(height: 0.5)
                            .padding(.leading, DesignTokens.Spacing.lg + DesignTokens.Spacing.sm + 7)
                    }
                }
            }
        }
    }

    // MARK: - Notification Row

    private func notificationRow(_ notification: NotificationItem) -> some View {
        Button {
            markAsRead(notification.id)
        } label: {
            HStack(alignment: .top, spacing: DesignTokens.Spacing.sm) {
                // Unread indicator dot
                Circle()
                    .fill(notification.isRead ? Color.clear : palette.accent)
                    .frame(width: 7, height: 7)
                    .padding(.top, 6)

                // Content
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(notification.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(palette.textPrimary)

                        Spacer()

                        Text(notification.timestamp)
                            .font(.caption2)
                            .foregroundStyle(palette.textTertiary)
                    }

                    Text(notification.body)
                        .font(.subheadline)
                        .foregroundStyle(palette.textSecondary)
                        .lineLimit(2)
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.vertical, DesignTokens.Spacing.sm + 1)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: "bell.slash")
                .font(.system(size: 48))
                .foregroundStyle(palette.textTertiary)

            Text("No Notifications")
                .font(.title3.weight(.semibold))
                .foregroundStyle(palette.textPrimary)

            Text("You're all caught up.")
                .font(.subheadline)
                .foregroundStyle(palette.textSecondary)
        }
    }

    // MARK: - Actions

    private func markAllRead() {
        withAnimation(.easeInOut(duration: 0.3)) {
            for index in notifications.indices {
                notifications[index].isRead = true
            }
        }
    }

    private func markAsRead(_ id: UUID) {
        guard let index = notifications.firstIndex(where: { $0.id == id }) else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            notifications[index].isRead = true
        }
    }
}

// MARK: - Preview

#Preview("Notification Center") {
    NavigationStack {
        NotificationCenterView()
    }
}

#Preview("Notification Center - Dark") {
    NavigationStack {
        NotificationCenterView()
    }
    .preferredColorScheme(.dark)
}
