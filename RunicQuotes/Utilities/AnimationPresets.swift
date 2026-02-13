//
//  AnimationPresets.swift
//  RunicQuotes
//

import SwiftUI

/// Centralized animation constants for consistent motion across the app.
enum AnimationPresets {
    static let gentleSpring = Animation.spring(response: 0.35, dampingFraction: 0.7)
    static let quickSnap = Animation.easeInOut(duration: 0.15)
    static let smoothEase = Animation.easeInOut(duration: 0.25)
    static let cardAppear = Animation.spring(response: 0.4, dampingFraction: 0.75)
}
