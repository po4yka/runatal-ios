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
    @Environment(\.colorScheme) private var colorScheme

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
        let palette = AppThemePalette.adaptive(for: colorScheme)

        ZStack {
            backgroundGradient(palette: palette)

            ScrollView {
                VStack(spacing: DesignTokens.Spacing.xl) {
                    header(palette: palette)
                    livePreviewSection(palette: palette)
                    appearanceSection(palette: palette)
                    scriptSection(palette: palette)
                    typographySection(palette: palette)
                    widgetSection(palette: palette)
                    accessibilitySection(palette: palette)
                    archiveLink(palette: palette)
                    aboutSection(palette: palette)

                    Spacer()
                        .frame(height: DesignTokens.Spacing.lg)
                }
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.vertical, DesignTokens.Spacing.xs)
            }
        }
        .task {
            guard !didInitialize else { return }
            didInitialize = true
            viewModel.configureIfNeeded(modelContext: modelContext)
            viewModel.onAppear()
        }
    }

    // MARK: - Background

    private func backgroundGradient(palette: AppThemePalette) -> some View {
        LinearGradient(
            colors: palette.appBackgroundGradient,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    // MARK: - Header

    private func header(palette: AppThemePalette) -> some View {
        HStack(spacing: DesignTokens.Spacing.xs) {
            Text("Settings")
                .font(.largeTitle.bold())
                .foregroundStyle(palette.textPrimary)

            Spacer()
        }
        .padding(.top, DesignTokens.Spacing.md)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Settings")
        .accessibilityIdentifier("settings_header")
    }

    // MARK: - Live Preview

    private func livePreviewSection(palette: AppThemePalette) -> some View {
        GlassCard(intensity: .strong) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                HStack {
                    Label("Live Preview", systemImage: "eye")
                        .font(.headline)
                        .foregroundStyle(palette.textPrimary)

                    Spacer()

                    Text(viewModel.selectedTheme.displayName)
                        .font(.caption)
                        .foregroundStyle(palette.textTertiary)
                }

                Text(viewModel.livePreviewRunicText)
                    .runicTextStyle(
                        script: viewModel.selectedScript,
                        font: viewModel.selectedFont,
                        style: .title2,
                        minSize: 22,
                        maxSize: 40
                    )
                    .foregroundStyle(palette.runeText)
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 0)
                    .lineSpacing(5)
                    .frame(maxWidth: .infinity, alignment: .center)

                Rectangle()
                    .fill(palette.separator)
                    .frame(height: 1)

                Text(viewModel.livePreviewLatinText)
                    .font(.callout)
                    .foregroundStyle(palette.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)

                HStack(spacing: DesignTokens.Spacing.sm) {
                    previewPill(label: "Script", value: viewModel.selectedScript.displayName, palette: palette)
                    previewPill(label: "Font", value: viewModel.selectedFont.displayName, palette: palette)
                }
            }
            .padding(DesignTokens.Spacing.xxs)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("settings_live_preview")
    }

    private func previewPill(label: String, value: String, palette: AppThemePalette) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(palette.textTertiary)

            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(palette.textPrimary)
                .lineLimit(1)
        }
        .padding(.horizontal, DesignTokens.Spacing.sm)
        .padding(.vertical, DesignTokens.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.sm)
                .fill(.ultraThinMaterial)
                .opacity(0.35)
        )
    }

    // MARK: - Appearance

    private func appearanceSection(palette: AppThemePalette) -> some View {
        GlassCard(intensity: .medium) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                sectionHeader("Appearance", icon: "paintbrush", palette: palette)

                VStack(spacing: DesignTokens.Spacing.sm) {
                    ForEach(AppTheme.allCases) { theme in
                        themeButton(theme, palette: palette)

                        if theme != AppTheme.allCases.last {
                            Rectangle()
                                .fill(palette.separator)
                                .frame(height: 1)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    settingsActionRow(
                        icon: "arrow.counterclockwise",
                        title: "Reset to Defaults",
                        isEnabled: !viewModel.isAtDefaults,
                        palette: palette
                    ) {
                        Haptics.trigger(.saveOrShare)
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.resetToDefaults()
                        }
                    }
                    .accessibilityIdentifier("settings_reset_defaults_button")

                    settingsActionRow(
                        icon: "wand.and.stars",
                        title: "Restore Last Preset",
                        isEnabled: viewModel.canRestoreLastPreset,
                        palette: palette
                    ) {
                        Haptics.trigger(.saveOrShare)
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.restoreLastUsedPreset()
                        }
                    }
                    .accessibilityIdentifier("settings_restore_preset_button")
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("settings_appearance_section")
    }

    private func themeButton(_ theme: AppTheme, palette: AppThemePalette) -> some View {
        let themePalette = theme.palette
        let isSelected = viewModel.selectedTheme == theme

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.updateTheme(theme)
            }
        } label: {
            HStack(spacing: DesignTokens.Spacing.sm) {
                HStack(spacing: DesignTokens.Spacing.xxs) {
                    Circle()
                        .fill(themePalette.appBackgroundGradient.first ?? .black)
                    Circle()
                        .fill(themePalette.appBackgroundGradient.dropFirst().first ?? .gray)
                    Circle()
                        .fill(themePalette.appBackgroundGradient.last ?? .white)
                }
                .frame(width: 48, height: 12)

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                    Text(theme.displayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(palette.textPrimary)

                    Text(theme.description)
                        .font(.caption)
                        .foregroundStyle(palette.textTertiary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(palette.accent)
                        .font(.title3)
                        .accessibilityLabel("Selected")
                }
            }
            .padding(.vertical, DesignTokens.Spacing.xxs)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("\(theme.displayName) theme")
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityHint("Double tap to select the \(theme.displayName) theme")
        .accessibilityIdentifier("settings_theme_\(theme.rawValue.replacingOccurrences(of: " ", with: "_"))")
    }

    // MARK: - Default Script

    private func scriptSection(palette: AppThemePalette) -> some View {
        GlassCard(intensity: .medium) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                sectionHeader("Default Script", icon: "character.book.closed", palette: palette)

                VStack(spacing: DesignTokens.Spacing.sm) {
                    ForEach(RunicScript.allCases) { script in
                        scriptRow(script, palette: palette)

                        if script != RunicScript.allCases.last {
                            Rectangle()
                                .fill(palette.separator)
                                .frame(height: 1)
                        }
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("settings_script_section")
    }

    private func scriptRow(_ script: RunicScript, palette: AppThemePalette) -> some View {
        let isSelected = viewModel.selectedScript == script
        let runicPreview = RunicTransliterator.transliterate("rune", to: script)

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.updateScript(script)
            }
        } label: {
            HStack(spacing: DesignTokens.Spacing.sm) {
                Text(runicPreview)
                    .runicTextStyle(
                        script: script,
                        font: viewModel.selectedFont,
                        style: .body,
                        minSize: 16,
                        maxSize: 22
                    )
                    .foregroundStyle(palette.runeText)
                    .frame(width: 40, alignment: .center)

                Text(script.displayName)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(palette.textPrimary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(palette.accent)
                        .font(.title3)
                        .accessibilityLabel("Selected")
                }
            }
            .padding(.vertical, DesignTokens.Spacing.xxs)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("\(script.displayName) script")
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityIdentifier("settings_script_\(script.rawValue)")
    }

    // MARK: - Typography

    private func typographySection(palette: AppThemePalette) -> some View {
        GlassCard(intensity: .medium) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                sectionHeader("Typography", icon: "textformat.size", palette: palette)

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text("Font")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(palette.textSecondary)

                    GlassFontSelector(
                        selectedFont: Binding(
                            get: { viewModel.selectedFont },
                            set: { viewModel.updateFont($0) }
                        ),
                        availableFonts: viewModel.availableFonts
                    )
                    .accessibilityLabel("Select font style")
                    .accessibilityValue(viewModel.selectedFont.rawValue)
                    .accessibilityHint("Choose the font used to display runic text")
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("settings_font_section")

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(palette.error)
                        .accessibilityLabel("Error: \(error)")
                }

                Rectangle()
                    .fill(palette.separator)
                    .frame(height: 1)

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text("Recommended Combinations")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(palette.textSecondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: DesignTokens.Spacing.sm) {
                            ForEach(viewModel.recommendedPresets) { preset in
                                presetCard(preset, palette: palette)
                            }
                        }
                        .padding(.vertical, DesignTokens.Spacing.xxs)
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("settings_typography_section")
    }

    private func presetCard(_ preset: ReadingPreset, palette: AppThemePalette) -> some View {
        let isActive = viewModel.selectedScript == preset.script && viewModel.selectedFont == preset.font

        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                viewModel.applyPreset(preset)
            }
        } label: {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                HStack(alignment: .top) {
                    Text(preset.displayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(palette.textPrimary)

                    Spacer(minLength: DesignTokens.Spacing.xs)

                    if isActive {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(palette.accent)
                            .font(.caption)
                    }
                }

                Text("\(preset.script.displayName) + \(preset.font.displayName)")
                    .font(.caption2)
                    .foregroundStyle(palette.textTertiary)
                    .lineLimit(1)

                Text(viewModel.presetPreviewRunicText(for: preset))
                    .runicTextStyle(
                        script: preset.script,
                        font: preset.font,
                        style: .body,
                        minSize: 16,
                        maxSize: 24
                    )
                    .foregroundStyle(palette.runeText)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(preset.previewLatinText)
                    .font(.caption)
                    .foregroundStyle(palette.textSecondary)
                    .lineLimit(2)

                Text(preset.description)
                    .font(.caption2)
                    .foregroundStyle(palette.textTertiary)
                    .lineLimit(2)
            }
            .padding(DesignTokens.Spacing.sm)
            .frame(width: 250, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md)
                    .fill(.ultraThinMaterial)
                    .opacity(isActive ? 0.5 : 0.2)
            }
            .shadow(
                color: .black.opacity(isActive ? 0.22 : 0),
                radius: 4,
                x: 0,
                y: 2
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityIdentifier("settings_preset_\(preset.rawValue.replacingOccurrences(of: " ", with: "_"))")
    }

    // MARK: - Widget

    private func widgetSection(palette: AppThemePalette) -> some View {
        GlassCard(intensity: .medium) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                sectionHeader("Widget", icon: "rectangle.on.rectangle", palette: palette)

                VStack(spacing: DesignTokens.Spacing.sm) {
                    ForEach(WidgetMode.allCases) { mode in
                        selectionRow(
                            title: mode.displayName,
                            subtitle: mode.description,
                            isSelected: viewModel.widgetMode == mode,
                            palette: palette
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                viewModel.updateWidgetMode(mode)
                            }
                        }
                        .accessibilityLabel("\(mode.displayName) mode")
                        .accessibilityValue(viewModel.widgetMode == mode ? "Selected" : "Not selected")
                        .accessibilityIdentifier("settings_widget_mode_\(mode.rawValue)")

                        if mode != WidgetMode.allCases.last {
                            Rectangle()
                                .fill(palette.separator)
                                .frame(height: 1)
                        }
                    }
                }

                Rectangle()
                    .fill(palette.separator)
                    .frame(height: 1)

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text("Widget Style")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(palette.textSecondary)

                    VStack(spacing: DesignTokens.Spacing.sm) {
                        ForEach(WidgetStyle.allCases) { style in
                            selectionRow(
                                title: style.displayName,
                                subtitle: style.description,
                                isSelected: viewModel.widgetStyle == style,
                                palette: palette
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    viewModel.updateWidgetStyle(style)
                                }
                            }
                            .accessibilityLabel("\(style.displayName) style")
                            .accessibilityValue(viewModel.widgetStyle == style ? "Selected" : "Not selected")
                            .accessibilityIdentifier("settings_widget_style_\(style.rawValue.replacingOccurrences(of: " ", with: "_"))")

                            if style != WidgetStyle.allCases.last {
                                Rectangle()
                                    .fill(palette.separator)
                                    .frame(height: 1)
                            }
                        }
                    }
                }

                Rectangle()
                    .fill(palette.separator)
                    .frame(height: 1)

                settingsToggleRow(
                    title: "Decorative Glyph Identity",
                    subtitle: "Enable glyph ring and background pattern in widgets",
                    isOn: Binding(
                        get: { viewModel.widgetDecorativeGlyphsEnabled },
                        set: { viewModel.updateWidgetDecorativeGlyphsEnabled($0) }
                    ),
                    palette: palette
                )
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Widget settings")
        .accessibilityIdentifier("settings_widget_section")
    }

    // MARK: - Accessibility

    private func accessibilitySection(palette: AppThemePalette) -> some View {
        GlassCard(intensity: .medium) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                sectionHeader("Accessibility", icon: "accessibility", palette: palette)

                settingsToggleRow(
                    title: "Reduce Transparency",
                    subtitle: "Replace glass with solid",
                    isOn: .constant(false),
                    palette: palette
                )

                Rectangle()
                    .fill(palette.separator)
                    .frame(height: 1)

                settingsToggleRow(
                    title: "Reduce Motion",
                    subtitle: "Minimize animations",
                    isOn: .constant(false),
                    palette: palette
                )
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("settings_accessibility_section")
    }

    // MARK: - Archive Link

    private func archiveLink(palette: AppThemePalette) -> some View {
        NavigationLink {
            ArchiveView()
        } label: {
            GlassCard(intensity: .medium) {
                HStack {
                    Image(systemName: "archivebox")
                        .font(.body)
                        .foregroundStyle(palette.accent)

                    Text("Archive")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(palette.textPrimary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(palette.textTertiary)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - About

    private func aboutSection(palette: AppThemePalette) -> some View {
        GlassCard(intensity: .medium) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                sectionHeader("About", icon: "info.circle", palette: palette)

                VStack(spacing: DesignTokens.Spacing.sm) {
                    aboutRow("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0", palette: palette)

                    Rectangle()
                        .fill(palette.separator)
                        .frame(height: 1)

                    aboutRow("Scripts", value: "\(RunicScript.allCases.count)", palette: palette)

                    Rectangle()
                        .fill(palette.separator)
                        .frame(height: 1)

                    aboutRow("Fonts", value: "\(RunicFont.allCases.count)", palette: palette)

                    Rectangle()
                        .fill(palette.separator)
                        .frame(height: 1)

                    HStack {
                        Text("Rate on App Store")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(palette.textPrimary)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(palette.textTertiary)
                    }
                    .padding(.vertical, DesignTokens.Spacing.xxs)
                }

                Text("Bringing ancient wisdom to modern devices")
                    .font(.caption)
                    .foregroundStyle(palette.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("settings_about_section")
    }

    private func aboutRow(_ label: String, value: String, palette: AppThemePalette) -> some View {
        HStack {
            Text(label)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(palette.textPrimary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .foregroundStyle(palette.textSecondary)
        }
        .padding(.vertical, DesignTokens.Spacing.xxs)
    }

    // MARK: - Shared UI

    private func sectionHeader(_ title: String, icon: String, palette: AppThemePalette) -> some View {
        HStack(spacing: DesignTokens.Spacing.xs) {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(palette.accent.opacity(0.4))
                .frame(width: 3, height: 20)

            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(palette.textSecondary)

            Text(title)
                .font(.headline)
                .foregroundStyle(palette.textPrimary)

            Spacer()
        }
    }

    private func selectionRow(
        title: String,
        subtitle: String,
        isSelected: Bool,
        palette: AppThemePalette,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                    Text(title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(palette.textPrimary)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(palette.textTertiary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(palette.accent)
                        .font(.title3)
                        .accessibilityLabel("Selected")
                }
            }
            .padding(.vertical, DesignTokens.Spacing.xxs)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func settingsToggleRow(
        title: String,
        subtitle: String,
        isOn: Binding<Bool>,
        palette: AppThemePalette
    ) -> some View {
        Toggle(isOn: isOn) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(palette.textPrimary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(palette.textTertiary)
            }
        }
        .tint(palette.accent)
    }

    private func settingsActionRow(
        icon: String,
        title: String,
        isEnabled: Bool,
        palette: AppThemePalette,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: DesignTokens.Spacing.xs) {
                Image(systemName: icon)
                    .font(.caption.weight(.semibold))
                Text(title)
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(palette.textPrimary.opacity(isEnabled ? 0.92 : 0.3))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, DesignTokens.Spacing.sm)
            .padding(.vertical, DesignTokens.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.sm)
                    .fill(.ultraThinMaterial)
                    .opacity(isEnabled ? 0.35 : 0.15)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isEnabled)
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
