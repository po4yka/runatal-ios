//
//  FeatureBuilders.swift
//  RunicQuotes
//
//  Created by Codex on 2026-03-13.
//

import Foundation

typealias QuoteSaveHandler = (Foundation.UUID?) -> Void

@MainActor
final class TranslationViewBuilder {
    private let makeViewClosure: () -> TranslationView

    init(makeView: @escaping () -> TranslationView) {
        makeViewClosure = makeView
    }

    func makeView() -> TranslationView {
        makeViewClosure()
    }
}

@MainActor
final class ArchiveViewBuilder {
    private let makeViewClosure: () -> ArchiveView

    init(makeView: @escaping () -> ArchiveView) {
        makeViewClosure = makeView
    }

    func makeView() -> ArchiveView {
        makeViewClosure()
    }
}

@MainActor
final class CreateEditQuoteViewBuilder {
    private let makeViewClosure: (CreateEditMode, QuoteSaveHandler?) -> CreateEditQuoteView

    init(makeView: @escaping (CreateEditMode, QuoteSaveHandler?) -> CreateEditQuoteView) {
        makeViewClosure = makeView
    }

    func makeView(
        mode: CreateEditMode,
        onSaved: QuoteSaveHandler?
    ) -> CreateEditQuoteView {
        makeViewClosure(mode, onSaved)
    }
}
