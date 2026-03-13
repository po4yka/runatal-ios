//
//  GlassScriptSelector.swift
//  RunicQuotes
//
//  Created by Claude on 2025-11-15.
//

import SwiftUI

/// A segmented control-style selector for runic scripts with glass design
struct GlassScriptSelector: View {
    // MARK: - Properties

    @Binding var selectedScript: RunicScript

    let cornerRadius: CGFloat
    let spacing: CGFloat
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.runicTheme) private var runicTheme

    // MARK: - Initialization

    init(
        selectedScript: Binding<RunicScript>,
        cornerRadius: CGFloat = 12,
        spacing: CGFloat = 8
    ) {
        self._selectedScript = selectedScript
        self.cornerRadius = cornerRadius
        self.spacing = spacing
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(RunicScript.allCases) { script in
                ScriptButton(
                    script: script,
                    isSelected: selectedScript == script,
                    cornerRadius: cornerRadius
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedScript = script
                    }
                    Haptics.trigger(.scriptSwitch)
                }
            }
        }
        .padding(4)
        .background {
            LiquidCard(
                palette: palette,
                role: .chrome,
                cornerRadius: cornerRadius + 4,
                shadowRadius: 0,
                contentPadding: 0,
                interactive: true
            ) {
                Color.clear
            }
        }
    }

    private var palette: AppThemePalette {
        AppThemePalette.themed(runicTheme, for: colorScheme)
    }
}

// MARK: - Script Button

private struct ScriptButton: View {
    let script: RunicScript
    let isSelected: Bool
    let cornerRadius: CGFloat
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.runicTheme) private var runicTheme

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                // Script icon/symbol
                Text(scriptSymbol)
                    .font(.system(size: 20, weight: .medium, design: .serif))
                    .fontWeight(.medium)

                // Script name
                Text(script.displayName)
                    .font(DesignTokens.Typography.metadata)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .foregroundStyle(isSelected ? palette.chipSelectedForeground : palette.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
        }
        .buttonStyle(LiquidProminentButtonStyle(palette: palette, emphasized: isSelected))
    }

    private var palette: AppThemePalette {
        AppThemePalette.themed(runicTheme, for: colorScheme)
    }

    private var scriptSymbol: String {
        switch script {
        case .elder:
            return "ᚠ" // Elder Futhark F-rune
        case .younger:
            return "ᚠ" // Younger Futhark F-rune
        case .cirth:
            return "⸸" // Decorative symbol (actual Cirth would use PUA)
        }
    }
}

// MARK: - Font Selector Variant

/// A selector for fonts with glass design
struct GlassFontSelector: View {
    @Binding var selectedFont: RunicFont
    let availableFonts: [RunicFont]

    let cornerRadius: CGFloat
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.runicTheme) private var runicTheme

    init(
        selectedFont: Binding<RunicFont>,
        availableFonts: [RunicFont] = RunicFont.allCases,
        cornerRadius: CGFloat = 12
    ) {
        self._selectedFont = selectedFont
        self.availableFonts = availableFonts
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(availableFonts) { font in
                FontButton(
                    font: font,
                    isSelected: selectedFont == font,
                    cornerRadius: cornerRadius
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedFont = font
                    }
                    Haptics.trigger(.scriptSwitch)
                }
            }
        }
    }

    private var palette: AppThemePalette {
        AppThemePalette.themed(runicTheme, for: colorScheme)
    }
}

// MARK: - Font Button

private struct FontButton: View {
    let font: RunicFont
    let isSelected: Bool
    let cornerRadius: CGFloat
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.runicTheme) private var runicTheme

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(font.displayName)
                        .font(DesignTokens.Typography.cardTitle)
                        .foregroundStyle(palette.textPrimary)

                    Text(font.description)
                        .font(.caption)
                        .foregroundStyle(palette.textSecondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(palette.accent)
                        .font(.title3)
                }
            }
            .padding()
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(isSelected ? palette.chipFill : palette.editorialInset)
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(
                        isSelected ? palette.strongCardStroke : palette.cardStroke,
                        lineWidth: DesignTokens.Stroke.hairline
                    )
            }
            .shadow(
                color: palette.shadowColor.opacity(isSelected ? 1 : 0),
                radius: 4,
                x: 0,
                y: 2
            )
        }
        .buttonStyle(.plain)
    }

    private var palette: AppThemePalette {
        AppThemePalette.themed(runicTheme, for: colorScheme)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        LinearGradient(
            colors: [.black, Color(white: 0.1), .black],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        VStack(spacing: 40) {
            VStack(spacing: 20) {
                Text("Script Selector")
                    .font(.headline)
                    .foregroundStyle(.white)

                GlassScriptSelector(
                    selectedScript: .constant(.elder)
                )
            }

            VStack(spacing: 20) {
                Text("Font Selector")
                    .font(.headline)
                    .foregroundStyle(.white)

                GlassFontSelector(
                    selectedFont: .constant(.noto)
                )
            }
        }
        .padding()
    }
}
