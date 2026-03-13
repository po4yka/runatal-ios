//
//  LiquidEffectPolicy.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import SwiftUI

enum LiquidSurfaceRole {
    case chrome
    case content
    case inset
    case floatingCallout
}

struct LiquidEffectPolicy {
    let role: LiquidSurfaceRole
    let reduceTransparency: Bool
    let isNested: Bool

    var shouldUseGlass: Bool {
        !self.reduceTransparency && !self.isNested && self.role != .content
    }

    @available(iOS 26.0, *)
    func glass(using palette: AppThemePalette, interactive: Bool = false) -> Glass {
        let base: Glass = switch self.role {
        case .chrome:
            .regular
        case .content:
            .identity
        case .inset:
            .clear
        case .floatingCallout:
            .regular
        }

        let tinted = base.tint(palette.chromeTint)
        return interactive ? tinted.interactive() : tinted
    }

    func fillColor(using palette: AppThemePalette) -> Color {
        switch self.role {
        case .chrome:
            palette.chromeFallback
        case .content:
            palette.contentPlate
        case .inset:
            palette.insetPlate
        case .floatingCallout:
            palette.contentPlateElevated
        }
    }

    func strokeColor(using palette: AppThemePalette) -> Color {
        switch self.role {
        case .chrome:
            palette.chromeStroke
        case .content:
            palette.contentStroke
        case .inset:
            palette.contentStroke.opacity(0.75)
        case .floatingCallout:
            palette.strongCardStroke
        }
    }
}
