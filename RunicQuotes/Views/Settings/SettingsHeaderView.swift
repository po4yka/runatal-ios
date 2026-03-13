//
//  SettingsHeaderView.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
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
            palette: self.palette,
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Settings")
        .accessibilityIdentifier("settings_header")
    }
}
