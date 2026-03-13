//
//  LiquidEffectPolicy.swift
//  RunicQuotes
//
//  Created by Codex on 2026-03-13.
//

import SwiftUI

enum LiquidSurfaceRole: Sendable {
    case chrome
    case content
    case inset
    case floatingCallout
}

struct LiquidEffectPolicy: Sendable {
    let role: LiquidSurfaceRole
    let reduceTransparency: Bool
    let isNested: Bool

    var shouldUseGlass: Bool {
        !reduceTransparency && !isNested && role != .content
    }

    @available(iOS 26.0, *)
    func glass(using palette: AppThemePalette, interactive: Bool = false) -> Glass {
        let base: Glass
        switch role {
        case .chrome:
            base = .regular
        case .content:
            base = .identity
        case .inset:
            base = .clear
        case .floatingCallout:
            base = .regular
        }

        let tinted = base.tint(palette.chromeTint)
        return interactive ? tinted.interactive() : tinted
    }

    func fillColor(using palette: AppThemePalette) -> Color {
        switch role {
        case .chrome:
            return palette.chromeFallback
        case .content:
            return palette.contentPlate
        case .inset:
            return palette.insetPlate
        case .floatingCallout:
            return palette.contentPlateElevated
        }
    }

    func strokeColor(using palette: AppThemePalette) -> Color {
        switch role {
        case .chrome:
            return palette.chromeStroke
        case .content:
            return palette.contentStroke
        case .inset:
            return palette.contentStroke.opacity(0.75)
        case .floatingCallout:
            return palette.strongCardStroke
        }
    }
}
