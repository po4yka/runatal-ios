//
//  WidgetRootComponent.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
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
            WidgetTimelineService(modelContainer: self.modelContainer)
        }
    }
}
