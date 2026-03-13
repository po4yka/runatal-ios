//
//  HomeAccessoryController.swift
//  RunicQuotes
//
//  Created by Codex on 2026-03-13.
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
        caption: String
    ) {
        collectionName = collection.displayName
        scriptName = script.displayName
        self.caption = caption
        isVisible = true
    }

    func hide() {
        isVisible = false
    }
}
