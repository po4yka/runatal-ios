//
//  AppSearchCoordinator.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import Foundation
import SwiftUI

final class AppSearchCoordinator: ObservableObject {
    @Published var query = ""
    @Published var isPresented = false

    init(query: String = "", isPresented: Bool = false) {
        self.query = query
        self.isPresented = isPresented
    }

    func clear() {
        self.query = ""
        self.isPresented = false
    }
}
