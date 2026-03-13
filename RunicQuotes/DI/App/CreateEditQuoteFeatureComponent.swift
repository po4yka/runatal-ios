//
//  CreateEditQuoteFeatureComponent.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import Foundation
import NeedleFoundation

protocol CreateEditQuoteFeatureDependency: Dependency {}

@MainActor
final class CreateEditQuoteFeatureComponent: Component<CreateEditQuoteFeatureDependency> {
    private let mode: CreateEditMode
    private let saveHandler: QuoteSaveHandler?
    private let quoteRepository: SwiftDataQuoteRepository

    init(
        parent: Scope,
        quoteRepository: SwiftDataQuoteRepository,
        mode: CreateEditMode,
        onSaved: QuoteSaveHandler?,
    ) {
        self.quoteRepository = quoteRepository
        self.mode = mode
        self.saveHandler = onSaved
        super.init(parent: parent)
    }

    var viewModel: CreateEditQuoteViewModel {
        CreateEditQuoteViewModel(
            quoteRepository: self.quoteRepository,
            mode: self.mode,
        )
    }

    func view() -> CreateEditQuoteView {
        CreateEditQuoteView(
            viewModel: self.viewModel,
            mode: self.mode,
            onSaved: self.saveHandler,
        )
    }
}
