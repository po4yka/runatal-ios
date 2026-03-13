//
//  SettingsHeaderView.swift
//  RunicQuotes
//
//  Created by Codex on 2026-03-13.
//

import SwiftUI

struct SettingsHeaderView: View {
    let palette: AppThemePalette

    var body: some View {
        HeroHeader(
            eyebrow: "Settings",
            title: "Reading Studio",
            subtitle: "Tune the atmosphere, type, and widget presence without losing the quiet of the app.",
            meta: ["Preview first", "Changes save immediately"],
            palette: palette
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Settings")
        .accessibilityIdentifier("settings_header")
    }
}
