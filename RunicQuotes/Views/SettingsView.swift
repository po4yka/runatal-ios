//
//  SettingsView.swift
//  RunicQuotes
//
//  Created by Claude on 2025-11-15.
//

import SwiftUI

/// Settings and preferences view
struct SettingsView: View {
    // MARK: - Properties

    @StateObject private var viewModel: SettingsViewModel
    @Environment(\.modelContext) private var modelContext

    // MARK: - Initialization

    init() {
        // Initialize with a placeholder - will be replaced in onAppear
        _viewModel = StateObject(wrappedValue: SettingsViewModel(
            modelContext: ModelContext(
                try! ModelContainer(for: Quote.self, UserPreferences.self)
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
            // Reinitialize viewModel with correct context
            let vm = SettingsViewModel(modelContext: modelContext)
            _viewModel.wrappedValue = vm
            viewModel.onAppear()
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                .pureBlack,
                .darkGray1,
                .darkGray2,
                .darkGray1,
                .pureBlack
            ],
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
                .foregroundColor(.white.opacity(0.8))

            Text("Settings")
                .font(.largeTitle.bold())
                .foregroundColor(.white)

            Text("Customize your runic experience")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.top, 20)
    }

    // MARK: - Script Section

    private var scriptSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeader("Runic Script", icon: "textformat")

                Text(viewModel.selectedScript.description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.bottom, 8)

                GlassScriptSelector(
                    selectedScript: $viewModel.selectedScript
                )
                .onChange(of: viewModel.selectedScript) { _, newValue in
                    viewModel.updateScript(newValue)
                }
            }
        }
    }

    // MARK: - Font Section

    private var fontSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeader("Font Style", icon: "textformat.size")

                Text("Choose your preferred runic font")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.bottom, 8)

                GlassFontSelector(
                    selectedFont: $viewModel.selectedFont,
                    availableFonts: viewModel.availableFonts
                )
                .onChange(of: viewModel.selectedFont) { _, newValue in
                    viewModel.updateFont(newValue)
                }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red.opacity(0.8))
                        .padding(.top, 8)
                }
            }
        }
    }

    // MARK: - Widget Section

    private var widgetSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeader("Widget Settings", icon: "rectangle.on.rectangle")

                Text("How should the widget display quotes?")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.bottom, 8)

                VStack(spacing: 12) {
                    ForEach(WidgetMode.allCases) { mode in
                        widgetModeButton(mode)
                    }
                }
            }
        }
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
                        .foregroundColor(.white)

                    Text(mode.description)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()

                if viewModel.widgetMode == mode {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                        .font(.title3)
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
    }

    // MARK: - About Section

    private var aboutSection: some View {
        GlassCard.light {
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
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }
        }
    }

    private func aboutRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))

            Spacer()

            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.white)
        }
    }

    // MARK: - Section Header

    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundColor(.white.opacity(0.8))

            Text(title)
                .font(.headline)
                .foregroundColor(.white)

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
    let container = try! ModelContainer(
        for: Quote.self, UserPreferences.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

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
