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
            RoundedRectangle(cornerRadius: cornerRadius + 4)
                .fill(.ultraThinMaterial)
                .opacity(0.3)
        }
    }
}

// MARK: - Script Button

private struct ScriptButton: View {
    let script: RunicScript
    let isSelected: Bool
    let cornerRadius: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                // Script icon/symbol
                Text(scriptSymbol)
                    .font(.title3)
                    .fontWeight(.medium)

                // Script name
                Text(script.displayName)
                    .font(.caption2)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .foregroundColor(isSelected ? .white : .white.opacity(0.6))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)
                        .opacity(0.5)
                        .shadow(color: .black.opacity(0.22), radius: 4, x: 0, y: 2)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
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
}

// MARK: - Font Button

private struct FontButton: View {
    let font: RunicFont
    let isSelected: Bool
    let cornerRadius: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(font.displayName)
                        .font(.headline)
                        .foregroundColor(.white)

                    Text(font.description)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.55))
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white.opacity(0.55))
                        .font(.title3)
                }
            }
            .padding()
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .opacity(isSelected ? 0.5 : 0.2)
            }
            .shadow(
                color: .black.opacity(isSelected ? 0.22 : 0),
                radius: 4,
                x: 0,
                y: 2
            )
        }
        .buttonStyle(PlainButtonStyle())
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
                    .foregroundColor(.white)

                GlassScriptSelector(
                    selectedScript: .constant(.elder)
                )
            }

            VStack(spacing: 20) {
                Text("Font Selector")
                    .font(.headline)
                    .foregroundColor(.white)

                GlassFontSelector(
                    selectedFont: .constant(.noto)
                )
            }
        }
        .padding()
    }
}
