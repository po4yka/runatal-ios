//
//  QuoteBackgroundView.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import SwiftUI

struct QuoteBackgroundView: View {
    let palette: AppThemePalette

    var body: some View {
        LinearGradient(
            colors: self.palette.appBackgroundGradient,
            startPoint: .topLeading,
            endPoint: .bottomTrailing,
        )
        .overlay {
            ZStack {
                Circle()
                    .fill(self.palette.accent.opacity(0.04))
                    .frame(width: 240, height: 240)
                    .blur(radius: 32)
                    .offset(x: 120, y: -220)

                Circle()
                    .fill(self.palette.accent.opacity(0.03))
                    .frame(width: 280, height: 280)
                    .blur(radius: 44)
                    .offset(x: -140, y: 260)
            }
        }
        .ignoresSafeArea()
    }
}
