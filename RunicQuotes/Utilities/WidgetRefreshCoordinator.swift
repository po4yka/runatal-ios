//
//  WidgetRefreshCoordinator.swift
//  RunicQuotes
//
//  Created by Claude on 09.10.26.
//

import Combine
import Foundation
import WidgetKit

@MainActor
protocol WidgetReloading: AnyObject {
    func reloadQuotes()
}

@MainActor
final class SystemWidgetReloader: WidgetReloading {
    func reloadQuotes() {
        WidgetCenter.shared.reloadTimelines(ofKind: "RunicQuoteWidget")
    }
}

/// A successful store mutation invalidates the external widget timeline, coalescing bursts into one reload.
@MainActor
final class WidgetRefreshCoordinator {
    private let reloader: any WidgetReloading
    private var subscriptions: Set<AnyCancellable> = []

    init(reloader: any WidgetReloading, notifications: NotificationCenter = .default) {
        self.reloader = reloader
        notifications.publisher(for: .preferencesDidChange)
            .merge(with: notifications.publisher(for: .libraryDidChange))
            .throttle(for: .milliseconds(150), scheduler: RunLoop.main, latest: true)
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in self?.reloader.reloadQuotes() }
            }
            .store(in: &self.subscriptions)
    }
}
