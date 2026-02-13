//
//  SettingsView.swift
//  RunicQuotes
//
//  Created by Claude on 2025-11-15.
//

import SwiftUI
import SwiftData

/// Settings and preferences view
struct SettingsView: View {
    // MARK: - Properties

    @StateObject private var viewModel: SettingsViewModel
    @State private var didInitialize = false
    @Environment(\.modelContext) private var modelContext

    // MARK: - Initialization

    init() {
        // Initialize with a placeholder - will be replaced in onAppear
        _viewModel = StateObject(wrappedValue: SettingsViewModel(
            modelContext: ModelContext(
                ModelContainerHelper.createPlaceholderContainer()
            )
        ))
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            backgroundGradient

            ScrollView {
                VStack(spacing: 24) {
                    header
                    livePreviewSection
                    readingSection
                    typographySection
                    widgetSection
                    aboutSection

                    Spacer()
                        .frame(height: 20)
                }
                .padding()
            }
        }
        .task {
            guard !didInitialize else { return }
            didInitialize = true
            viewModel.configureIfNeeded(modelContext: modelContext)
            viewModel.onAppear()
        }
    }

    private var themePalette: AppThemePalette {
        viewModel.selectedTheme.palette
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        LinearGradient(
            colors: themePalette.appBackgroundGradient,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "gear")
                .font(.system(size: 50))
                .foregroundColor(themePalette.secondaryText)
                .accessibilityHidden(true)

            Text("Settings")
                .font(.largeTitle.bold())
                .foregroundColor(themePalette.primaryText)

            Text("Customize your runic experience")
                .font(.subheadline)
                .foregroundColor(themePalette.tertiaryText)
        }
        .padding(.top, 20)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Settings - Customize your runic experience")
        .accessibilityIdentifier("settings_header")
    }

    // MARK: - Live Preview

    private var livePreviewSection: some View {
        GlassCard(opacity: .medium, blur: .regularMaterial) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label("Live Preview", systemImage: "eye")
                        .font(.headline)
                        .foregroundColor(themePalette.primaryText)

                    Spacer()

                    Text(viewModel.selectedTheme.displayName)
                        .font(.caption)
                        .foregroundColor(themePalette.tertiaryText)
                }

                Text(viewModel.livePreviewRunicText)
                    .runicTextStyle(
                        script: viewModel.selectedScript,
                        font: viewModel.selectedFont,
                        style: .title2,
                        minSize: 22,
                        maxSize: 40
                    )
                    .foregroundColor(themePalette.primaryText)
                    .lineSpacing(5)
                    .frame(maxWidth: .infinity, alignment: .center)

                Divider()
                    .overlay(themePalette.divider)

                Text(viewModel.livePreviewLatinText)
                    .font(.callout)
                    .foregroundColor(themePalette.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .center)

                HStack(spacing: 10) {
                    previewPill(label: "Script", value: viewModel.selectedScript.displayName)
                    previewPill(label: "Font", value: viewModel.selectedFont.displayName)
                }
            }
            .padding(2)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("settings_live_preview")
    }

    private func previewPill(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundColor(themePalette.tertiaryText)

            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundColor(themePalette.primaryText)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.thinMaterial)
                .opacity(0.35)
        )
    }

    // MARK: - Reading Group

    private var readingSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeader("Reading", icon: "book.closed")

                Text("Choose your script and visual atmosphere.")
                    .font(.caption)
                    .foregroundColor(themePalette.tertiaryText)

                VStack(alignment: .leading, spacing: 10) {
                    subsectionTitle("Runic Script")

                    GlassScriptSelector(
                        selectedScript: $viewModel.selectedScript
                    )
                    .onChange(of: viewModel.selectedScript) { _, newValue in
                        viewModel.updateScript(newValue)
                    }
                    .accessibilityLabel("Select runic script")
                    .accessibilityValue(viewModel.selectedScript.rawValue)
                    .accessibilityHint("Choose between Elder Futhark, Younger Futhark, or Cirth")
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("settings_script_section")

                VStack(alignment: .leading, spacing: 10) {
                    subsectionTitle("Theme")

                    VStack(spacing: 10) {
                        ForEach(AppTheme.allCases) { theme in
                            themeButton(theme)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    subsectionTitle("Quick Actions")

                    GlassButton.secondary(
                        "Reset to Defaults",
                        icon: "arrow.counterclockwise",
                        hapticTier: .saveOrShare
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.resetToDefaults()
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .disabled(viewModel.isAtDefaults)
                    .accessibilityIdentifier("settings_reset_defaults_button")

                    GlassButton.secondary(
                        "Restore Last Preset",
                        icon: "wand.and.stars",
                        hapticTier: .saveOrShare
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.restoreLastUsedPreset()
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .disabled(!viewModel.canRestoreLastPreset)
                    .accessibilityIdentifier("settings_restore_preset_button")
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("settings_reading_section")
    }

    private func themeButton(_ theme: AppTheme) -> some View {
        let palette = theme.palette

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.updateTheme(theme)
            }
        } label: {
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(palette.appBackgroundGradient.first ?? .black)
                    Circle()
                        .fill(palette.appBackgroundGradient.dropFirst().first ?? .gray)
                    Circle()
                        .fill(palette.appBackgroundGradient.last ?? .white)
                }
                .frame(width: 48, height: 12)

                VStack(alignment: .leading, spacing: 4) {
                    Text(theme.displayName)
                        .font(.headline)
                        .foregroundColor(themePalette.primaryText)

                    Text(theme.description)
                        .font(.caption)
                        .foregroundColor(themePalette.tertiaryText)
                }

                Spacer()

                if viewModel.selectedTheme == theme {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(themePalette.accent)
                        .font(.title3)
                        .accessibilityLabel("Selected")
                }
            }
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.thinMaterial)
                    .opacity(viewModel.selectedTheme == theme ? 0.5 : 0.2)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("\(theme.displayName) theme")
        .accessibilityValue(viewModel.selectedTheme == theme ? "Selected" : "Not selected")
        .accessibilityHint("Double tap to select the \(theme.displayName) theme")
        .accessibilityIdentifier("settings_theme_\(theme.rawValue.replacingOccurrences(of: " ", with: "_"))")
    }

    // MARK: - Typography Group

    private var typographySection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeader("Typography", icon: "textformat.size")

                Text("Adjust font details and use curated script/font combinations.")
                    .font(.caption)
                    .foregroundColor(themePalette.tertiaryText)

                VStack(alignment: .leading, spacing: 10) {
                    subsectionTitle("Font")

                    GlassFontSelector(
                        selectedFont: $viewModel.selectedFont,
                        availableFonts: viewModel.availableFonts
                    )
                    .onChange(of: viewModel.selectedFont) { _, newValue in
                        viewModel.updateFont(newValue)
                    }
                    .accessibilityLabel("Select font style")
                    .accessibilityValue(viewModel.selectedFont.rawValue)
                    .accessibilityHint("Choose the font used to display runic text")
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("settings_font_section")

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red.opacity(0.8))
                        .accessibilityLabel("Error: \(error)")
                }

                VStack(alignment: .leading, spacing: 10) {
                    subsectionTitle("Recommended Combinations")

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(viewModel.recommendedPresets) { preset in
                                presetCard(preset)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("settings_typography_section")
    }

    private func presetCard(_ preset: ReadingPreset) -> some View {
        let isActive = viewModel.selectedScript == preset.script && viewModel.selectedFont == preset.font

        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                viewModel.applyPreset(preset)
            }
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    Text(preset.displayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(themePalette.primaryText)

                    Spacer(minLength: 8)

                    if isActive {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(themePalette.accent)
                            .font(.caption)
                    }
                }

                Text("\(preset.script.displayName) + \(preset.font.displayName)")
                    .font(.caption2)
                    .foregroundColor(themePalette.tertiaryText)
                    .lineLimit(1)

                Text(viewModel.presetPreviewRunicText(for: preset))
                    .runicTextStyle(
                        script: preset.script,
                        font: preset.font,
                        style: .body,
                        minSize: 16,
                        maxSize: 24
                    )
                    .foregroundColor(themePalette.primaryText)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(preset.previewLatinText)
                    .font(.caption)
                    .foregroundColor(themePalette.secondaryText)
                    .lineLimit(2)

                Text(preset.description)
                    .font(.caption2)
                    .foregroundColor(themePalette.tertiaryText)
                    .lineLimit(2)
            }
            .padding(12)
            .frame(width: 250, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.thinMaterial)
                    .opacity(isActive ? 0.5 : 0.2)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(themePalette.divider, lineWidth: isActive ? 1.2 : 0.7)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityIdentifier("settings_preset_\(preset.rawValue.replacingOccurrences(of: " ", with: "_"))")
    }

    // MARK: - Widget Group

    private var widgetSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeader("Widget", icon: "rectangle.on.rectangle")

                Text("How should the widget display quotes?")
                    .font(.caption)
                    .foregroundColor(themePalette.tertiaryText)

                VStack(spacing: 12) {
                    ForEach(WidgetMode.allCases) { mode in
                        widgetModeButton(mode)
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    subsectionTitle("Widget Style")

                    VStack(spacing: 10) {
                        ForEach(WidgetStyle.allCases) { style in
                            widgetStyleButton(style)
                        }
                    }
                }

                Toggle(isOn: Binding(
                    get: { viewModel.widgetDecorativeGlyphsEnabled },
                    set: { viewModel.updateWidgetDecorativeGlyphsEnabled($0) }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Decorative Glyph Identity")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(themePalette.primaryText)

                        Text("Enable glyph ring and background pattern in widgets")
                            .font(.caption2)
                            .foregroundColor(themePalette.tertiaryText)
                    }
                }
                .tint(themePalette.accent)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Widget settings")
        .accessibilityIdentifier("settings_widget_section")
    }

    private func widgetModeButton(_ mode: WidgetMode) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                viewModel.updateWidgetMode(mode)
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(mode.displayName)
                        .font(.headline)
                        .foregroundColor(themePalette.primaryText)

                    Text(mode.description)
                        .font(.caption)
                        .foregroundColor(themePalette.tertiaryText)
                }

                Spacer()

                if viewModel.widgetMode == mode {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(themePalette.accent)
                        .font(.title3)
                        .accessibilityLabel("Selected")
                }
            }
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.thinMaterial)
                    .opacity(viewModel.widgetMode == mode ? 0.5 : 0.2)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("\(mode.displayName) mode")
        .accessibilityValue(viewModel.widgetMode == mode ? "Selected" : "Not selected")
        .accessibilityHint("Double tap to select \(mode.displayName) mode. \(mode.description)")
        .accessibilityIdentifier("settings_widget_mode_\(mode.rawValue)")
    }

    private func widgetStyleButton(_ style: WidgetStyle) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                viewModel.updateWidgetStyle(style)
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(style.displayName)
                        .font(.headline)
                        .foregroundColor(themePalette.primaryText)

                    Text(style.description)
                        .font(.caption)
                        .foregroundColor(themePalette.tertiaryText)
                }

                Spacer()

                if viewModel.widgetStyle == style {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(themePalette.accent)
                        .font(.title3)
                        .accessibilityLabel("Selected")
                }
            }
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.thinMaterial)
                    .opacity(viewModel.widgetStyle == style ? 0.5 : 0.2)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("\(style.displayName) style")
        .accessibilityValue(viewModel.widgetStyle == style ? "Selected" : "Not selected")
        .accessibilityHint("Double tap to select \(style.displayName) style. \(style.description)")
        .accessibilityIdentifier("settings_widget_style_\(style.rawValue.replacingOccurrences(of: " ", with: "_"))")
    }

    // MARK: - About Group

    private var aboutSection: some View {
        GlassCard(
            opacity: .veryLow,
            blur: .ultraThinMaterial
        ) {
            VStack(spacing: 12) {
                sectionHeader("About", icon: "info.circle")

                VStack(spacing: 8) {
                    aboutRow("App", value: "Runic Quotes")
                    aboutRow("Version", value: "1.0")
                    aboutRow("Scripts", value: "\(RunicScript.allCases.count)")
                    aboutRow("Fonts", value: "\(RunicFont.allCases.count)")
                }

                Text("Bringing ancient wisdom to modern devices")
                    .font(.caption)
                    .foregroundColor(themePalette.tertiaryText)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("settings_about_section")
    }

    private func aboutRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(themePalette.tertiaryText)

            Spacer()

            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundColor(themePalette.primaryText)
        }
    }

    // MARK: - Shared UI

    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundColor(themePalette.secondaryText)

            Text(title)
                .font(.headline)
                .foregroundColor(themePalette.primaryText)

            Spacer()
        }
    }

    private func subsectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundColor(themePalette.secondaryText)
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .modelContainer(for: [Quote.self, UserPreferences.self], inMemory: true)
}

#Preview("With Data") {
    let container = ModelContainerHelper.createPlaceholderContainer()

    // Create preferences
    let prefs = UserPreferences(
        selectedScript: .cirth,
        selectedFont: .cirth,
        widgetMode: .random,
        selectedTheme: .nordicDawn,
        lastUsedPreset: .cirthLore
    )
    container.mainContext.insert(prefs)

    return SettingsView()
        .modelContainer(container)
}
