//
//  WidgetRootComponent.swift
//  RunicQuotesWidget
//
//  Created by Codex on 2026-03-13.
//

import NeedleFoundation
import SwiftData

final class WidgetRootComponent: BootstrapComponent {
    let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        super.init()
    }

    var timelineService: WidgetTimelineService {
        shared {
            WidgetTimelineService(modelContainer: modelContainer)
        }
    }
}
