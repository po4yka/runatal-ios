//
//  DailyReminderView.swift
//  RunicQuotes
//
//  Created by Claude on 09.10.26.
//

import SwiftUI

struct DailyReminderView: View {
    @ObservedObject var viewModel: DailyReminderViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            HStack {
                Text("Daily reading reminder")
                    .accessibilityHidden(true)
                Spacer()
                Toggle("Daily reading reminder", isOn: Binding(
                    get: { self.viewModel.state.isEnabled },
                    set: { value in Task { await self.viewModel.setEnabled(value) } },
                ))
                .labelsHidden()
                .fixedSize()
                .frame(minHeight: 44)
                .accessibilityLabel("Daily reading reminder")
                .accessibilityIdentifier("daily_reminder_enabled")
            }
            DatePicker("Reminder time", selection: Binding(
                get: { self.viewModel.state.time.date },
                set: { date in Task { await self.viewModel.setTime(date) } },
            ), displayedComponents: .hourAndMinute)
                .accessibilityIdentifier("daily_reminder_time")
            Text("A reminder to open today’s passage. The passage is selected when you open the app.")
                .font(.caption)
            if let error = self.viewModel.state.errorMessage {
                Text(error).foregroundStyle(.red).accessibilityIdentifier("daily_reminder_error")
            }
        }
        .disabled(self.viewModel.state.isWorking)
        .task { await self.viewModel.onAppear() }
    }
}
