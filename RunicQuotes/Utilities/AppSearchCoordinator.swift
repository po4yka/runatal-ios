//
//  AppSearchCoordinator.swift
//  RunicQuotes
//
//  Created by Codex on 2026-03-13.
//

import Foundation
import SwiftUI

final class AppSearchCoordinator: ObservableObject {
    @Published var query = ""
    @Published var isPresented = false

    func clear() {
        query = ""
        isPresented = false
    }
}
