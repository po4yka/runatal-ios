//
//  HomeAccessoryController.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import Foundation

final class HomeAccessoryController: ObservableObject {
    @Published private(set) var collectionName = QuoteCollection.all.displayName
    @Published private(set) var scriptName = RunicScript.elder.displayName
    @Published private(set) var caption = "Continue reading"
    @Published private(set) var isVisible = false

    func update(
        collection: QuoteCollection,
        script: RunicScript,
        caption: String,
    ) {
        self.collectionName = collection.displayName
        self.scriptName = script.displayName
        self.caption = caption
        self.isVisible = true
    }

    func hide() {
        self.isVisible = false
    }
}
