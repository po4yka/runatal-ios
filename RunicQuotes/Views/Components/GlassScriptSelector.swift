//
//  GlassScriptSelector.swift
//  RunicQuotes
//
//  Created by Claude on 07.10.25.
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
        spacing: CGFloat = 8,
    ) {
        self._selectedScript = selectedScript
        self.cornerRadius = cornerRadius
        self.spacing = spacing
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: self.spacing) {
            ForEach(RunicScript.allCases) { script in
                ScriptButton(
                    script: script,
                    isSelected: self.selectedScript == script,
                    cornerRadius: self.cornerRadius,
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        self.selectedScript = script
                    }
                    Haptics.trigger(.scriptSwitch)
                }
            }
        }
        .padding(4)
        .background {
            LiquidCard(
                palette: self.palette,
                role: .chrome,
                cornerRadius: self.cornerRadius + 4,
                shadowRadius: 0,
                contentPadding: 0,
                interactive: true,
            ) {
                Color.clear
            }
        }
    }

    private var palette: AppThemePalette {
        AppThemePalette.themed(self.runicTheme, for: self.colorScheme)
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
        Button(action: self.action) {
            VStack(spacing: 4) {
                // Script icon/symbol
                Text(self.scriptSymbol)
                    .font(.system(size: 20, weight: .medium, design: .serif))
                    .fontWeight(.medium)

                // Script name
                Text(self.script.displayName)
                    .font(DesignTokens.Typography.metadata)
                    .fontWeight(self.isSelected ? .semibold : .regular)
            }
            .foregroundStyle(self.isSelected ? self.palette.chipSelectedForeground : self.palette.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
        }
        .buttonStyle(LiquidProminentButtonStyle(palette: self.palette, emphasized: self.isSelected))
    }

    private var palette: AppThemePalette {
        AppThemePalette.themed(self.runicTheme, for: self.colorScheme)
    }

    private var scriptSymbol: String {
        switch self.script {
        case .elder:
            "ᚠ" // Elder Futhark F-rune
        case .younger:
            "ᚠ" // Younger Futhark F-rune
        case .cirth:
            "⸸" // Decorative symbol (actual Cirth would use PUA)
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
        cornerRadius: CGFloat = 12,
    ) {
        self._selectedFont = selectedFont
        self.availableFonts = availableFonts
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(self.availableFonts) { font in
                FontButton(
                    font: font,
                    isSelected: self.selectedFont == font,
                    cornerRadius: self.cornerRadius,
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        self.selectedFont = font
                    }
                    Haptics.trigger(.scriptSwitch)
                }
            }
        }
    }

    private var palette: AppThemePalette {
        AppThemePalette.themed(self.runicTheme, for: self.colorScheme)
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
        Button(action: self.action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(self.font.displayName)
                        .font(DesignTokens.Typography.cardTitle)
                        .foregroundStyle(self.palette.textPrimary)

                    Text(self.font.description)
                        .font(.caption)
                        .foregroundStyle(self.palette.textSecondary)
                }

                Spacer()

                if self.isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(self.palette.accent)
                        .font(.title3)
                }
            }
            .padding()
            .background {
                RoundedRectangle(cornerRadius: self.cornerRadius)
                    .fill(self.isSelected ? self.palette.chipFill : self.palette.editorialInset)
            }
            .overlay {
                RoundedRectangle(cornerRadius: self.cornerRadius)
                    .strokeBorder(
                        self.isSelected ? self.palette.strongCardStroke : self.palette.cardStroke,
                        lineWidth: DesignTokens.Stroke.hairline,
                    )
            }
            .shadow(
                color: self.palette.shadowColor.opacity(self.isSelected ? 1 : 0),
                radius: 4,
                x: 0,
                y: 2,
            )
        }
        .buttonStyle(.plain)
    }

    private var palette: AppThemePalette {
        AppThemePalette.themed(self.runicTheme, for: self.colorScheme)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        LinearGradient(
            colors: [.black, Color(white: 0.1), .black],
            startPoint: .topLeading,
            endPoint: .bottomTrailing,
        )
        .ignoresSafeArea()

        VStack(spacing: 40) {
            VStack(spacing: 20) {
                Text("Script Selector")
                    .font(.headline)
                    .foregroundStyle(.white)

                GlassScriptSelector(
                    selectedScript: .constant(.elder),
                )
            }

            VStack(spacing: 20) {
                Text("Font Selector")
                    .font(.headline)
                    .foregroundStyle(.white)

                GlassFontSelector(
                    selectedFont: .constant(.noto),
                )
            }
        }
        .padding()
    }
}
