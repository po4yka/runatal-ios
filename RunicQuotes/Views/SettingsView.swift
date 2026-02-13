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
            // Background
            backgroundGradient

            // Content
            ScrollView {
                VStack(spacing: 30) {
                    // Header
                    header

                    // Script selection
                    scriptSection

                    // Font selection
                    fontSection

                    // Theme selection
                    themeSection

                    // Widget settings
                    widgetSection

                    // About section
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

    // MARK: - Script Section

    private var scriptSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeader("Runic Script", icon: "textformat")

                Text(viewModel.selectedScript.description)
                    .font(.caption)
                    .foregroundColor(themePalette.tertiaryText)
                    .padding(.bottom, 8)

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
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("settings_script_section")
    }

    // MARK: - Font Section

    private var fontSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeader("Font Style", icon: "textformat.size")

                Text("Choose your preferred runic font")
                    .font(.caption)
                    .foregroundColor(themePalette.tertiaryText)
                    .padding(.bottom, 8)

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

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red.opacity(0.8))
                        .padding(.top, 8)
                        .accessibilityLabel("Error: \(error)")
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("settings_font_section")
    }

    // MARK: - Theme Section

    private var themeSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeader("Theme", icon: "paintpalette")

                Text(viewModel.selectedTheme.description)
                    .font(.caption)
                    .foregroundColor(themePalette.tertiaryText)
                    .padding(.bottom, 8)

                VStack(spacing: 12) {
                    ForEach(AppTheme.allCases) { theme in
                        themeButton(theme)
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("settings_theme_section")
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

    // MARK: - Widget Section

    private var widgetSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeader("Widget Settings", icon: "rectangle.on.rectangle")

                Text("How should the widget display quotes?")
                    .font(.caption)
                    .foregroundColor(themePalette.tertiaryText)
                    .padding(.bottom, 8)

                VStack(spacing: 12) {
                    ForEach(WidgetMode.allCases) { mode in
                        widgetModeButton(mode)
                    }
                }
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

    // MARK: - About Section

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

    // MARK: - Section Header

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
        widgetMode: .random
    )
    container.mainContext.insert(prefs)

    return SettingsView()
        .modelContainer(container)
}
