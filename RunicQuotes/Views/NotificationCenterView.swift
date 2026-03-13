//
//  NotificationCenterView.swift
//  RunicQuotes
//
//  Created by Claude on 12.03.26.
//

import SwiftUI

// MARK: - Notification Item

/// Represents a single in-app notification.
struct NotificationItem: Identifiable {
    let id: UUID
    let title: String
    let body: String
    let timestamp: String
    var isRead: Bool

    static var previewSamples: [NotificationItem] {
        [
            NotificationItem(
                id: UUID(),
                title: "Daily Quote Ready",
                body: "Your new quote of the day is waiting.",
                timestamp: "Now",
                isRead: false,
            ),
            NotificationItem(
                id: UUID(),
                title: "Streak Reminder",
                body: "You have a 12-day streak. Don't break it!",
                timestamp: "2h ago",
                isRead: false,
            ),
            NotificationItem(
                id: UUID(),
                title: "New Pack Available",
                body: "Havamal Selections -- 32 quotes from Norse wisdom.",
                timestamp: "Yesterday",
                isRead: true,
            ),
            NotificationItem(
                id: UUID(),
                title: "Weekly Summary",
                body: "You read 14 quotes this week. Nice pace.",
                timestamp: "3 days ago",
                isRead: true,
            ),
        ]
    }
}

// MARK: - NotificationCenterView

/// In-app notification inbox matching the Figma Notification Center design.
struct NotificationCenterView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.runicTheme) private var runicTheme
    @State private var notifications: [NotificationItem] = []

    private var palette: AppThemePalette {
        .themed(self.runicTheme, for: self.colorScheme)
    }

    private var hasUnread: Bool {
        self.notifications.contains { !$0.isRead }
    }

    // MARK: - Body

    var body: some View {
        LiquidListScaffold(palette: self.palette) {
            Section {
                HeroHeader(
                    eyebrow: "Notifications",
                    title: "Inbox",
                    subtitle: self.notifications.isEmpty
                        ? "This build does not keep a synced notification history yet."
                        : "Updates tied to your reading cadence appear here.",
                    meta: [self.hasUnread ? "Unread items waiting" : "No unread items"],
                    palette: self.palette,
                )
                .listRowInsets(EdgeInsets(
                    top: DesignTokens.Spacing.lg,
                    leading: DesignTokens.Spacing.md,
                    bottom: DesignTokens.Spacing.md,
                    trailing: DesignTokens.Spacing.md,
                ))
            }

            Section {
                if self.notifications.isEmpty {
                    self.emptyState
                } else {
                    self.notificationList
                }
            }
        }
        .navigationTitle("Notifications")
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    if self.hasUnread {
                        Button("Mark All Read") {
                            self.markAllRead()
                        }
                        .font(.subheadline)
                        .foregroundStyle(self.palette.accent)
                    }
                }
            }
    }

    // MARK: - Notification List

    private var notificationList: some View {
        ForEach(self.notifications) { notification in
            self.notificationRow(notification)
        }
    }

    // MARK: - Notification Row

    private func notificationRow(_ notification: NotificationItem) -> some View {
        Button {
            self.markAsRead(notification.id)
        } label: {
            HStack(alignment: .top, spacing: DesignTokens.Spacing.sm) {
                Circle()
                    .fill(notification.isRead ? self.palette.separator.opacity(0.4) : self.palette.accent)
                    .frame(width: 8, height: 8)
                    .padding(.top, 5)

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                    HStack(alignment: .top, spacing: DesignTokens.Spacing.sm) {
                        Text(notification.title)
                            .font(DesignTokens.Typography.bodyEmphasis)
                            .foregroundStyle(self.palette.textPrimary)

                        Spacer(minLength: DesignTokens.Spacing.sm)

                        Text(notification.timestamp)
                            .font(DesignTokens.Typography.listMeta)
                            .foregroundStyle(self.palette.textTertiary)
                    }

                    Text(notification.body)
                        .font(DesignTokens.Typography.supportingBody)
                        .foregroundStyle(self.palette.textSecondary)
                        .lineLimit(2)
                }
            }
            .padding(DesignTokens.Spacing.md)
            .background {
                RoundedRectangle(
                    cornerRadius: DesignTokens.CornerRadius.lg,
                    style: .continuous,
                )
                .fill(self.palette.rowFill)
            }
            .overlay {
                RoundedRectangle(
                    cornerRadius: DesignTokens.CornerRadius.lg,
                    style: .continuous,
                )
                .strokeBorder(
                    self.palette.contentStroke.opacity(0.85),
                    lineWidth: DesignTokens.Stroke.hairline,
                )
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        EditorialEmptyState(
            palette: self.palette,
            icon: "bell.slash",
            eyebrow: "Coming Later",
            title: "History is not stored here yet",
            message: "Notification permissions and widget refresh still work, but past alerts are not collected into an inbox in this build.",
        )
    }

    // MARK: - Actions

    private func markAllRead() {
        withAnimation(.easeInOut(duration: 0.3)) {
            for index in self.notifications.indices {
                self.notifications[index].isRead = true
            }
        }
    }

    private func markAsRead(_ id: UUID) {
        guard let index = notifications.firstIndex(where: { $0.id == id }) else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            self.notifications[index].isRead = true
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
