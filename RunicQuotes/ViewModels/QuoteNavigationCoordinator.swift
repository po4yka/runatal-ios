//
//  QuoteNavigationCoordinator.swift
//  RunicQuotes
//
//  Created by Claude on 09.10.26.
//

import Combine
import Foundation

struct QuoteNavigationRequest: Equatable, Sendable {
    let id: UUID?
    let script: RunicScript?
    let mode: WidgetMode?
    let collection: QuoteCollection?
}

@MainActor
final class QuoteNavigationCoordinator: ObservableObject {
    @Published private(set) var pendingRequest: QuoteNavigationRequest?

    func openQuote(id: UUID?, script: RunicScript?, mode: WidgetMode?, collection: QuoteCollection?) {
        self.pendingRequest = QuoteNavigationRequest(id: id, script: script, mode: mode, collection: collection)
        NotificationCenter.default.post(name: .switchToQuoteTab, object: nil)
    }

    func consumePendingRequest() -> QuoteNavigationRequest? {
        let request = self.pendingRequest
        self.pendingRequest = nil
        return request
    }

    static func preview() -> QuoteNavigationCoordinator {
        QuoteNavigationCoordinator()
    }
}
