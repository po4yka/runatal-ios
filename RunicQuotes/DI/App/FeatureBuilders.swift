//
//  FeatureBuilders.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import Foundation

typealias QuoteSaveHandler = (Foundation.UUID?) -> Void

@MainActor
final class TranslationViewBuilder {
    private let makeViewClosure: () -> TranslationView

    init(makeView: @escaping () -> TranslationView) {
        self.makeViewClosure = makeView
    }

    func makeView() -> TranslationView {
        self.makeViewClosure()
    }
}

@MainActor
final class ArchiveViewBuilder {
    private let makeViewClosure: () -> ArchiveView

    init(makeView: @escaping () -> ArchiveView) {
        self.makeViewClosure = makeView
    }

    func makeView() -> ArchiveView {
        self.makeViewClosure()
    }
}

@MainActor
final class CreateEditQuoteViewBuilder {
    private let makeViewClosure: (CreateEditMode, QuoteSaveHandler?) -> CreateEditQuoteView

    init(makeView: @escaping (CreateEditMode, QuoteSaveHandler?) -> CreateEditQuoteView) {
        self.makeViewClosure = makeView
    }

    func makeView(
        mode: CreateEditMode,
        onSaved: QuoteSaveHandler?,
    ) -> CreateEditQuoteView {
        self.makeViewClosure(mode, onSaved)
    }
}
