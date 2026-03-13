//
//  CreateEditQuoteFeatureComponent.swift
//  RunicQuotes
//
//  Created by Codex on 2026-03-13.
//

import Foundation
import NeedleFoundation

protocol CreateEditQuoteFeatureDependency: Dependency { }

@MainActor
final class CreateEditQuoteFeatureComponent: Component<CreateEditQuoteFeatureDependency> {
    private let mode: CreateEditMode
    private let saveHandler: QuoteSaveHandler?
    private let quoteRepository: SwiftDataQuoteRepository

    init(
        parent: Scope,
        quoteRepository: SwiftDataQuoteRepository,
        mode: CreateEditMode,
        onSaved: QuoteSaveHandler?
    ) {
        self.quoteRepository = quoteRepository
        self.mode = mode
        saveHandler = onSaved
        super.init(parent: parent)
    }

    var viewModel: CreateEditQuoteViewModel {
        CreateEditQuoteViewModel(
            quoteRepository: quoteRepository,
            mode: mode
        )
    }

    func view() -> CreateEditQuoteView {
        CreateEditQuoteView(
            viewModel: viewModel,
            mode: mode,
            onSaved: saveHandler
        )
    }
}
