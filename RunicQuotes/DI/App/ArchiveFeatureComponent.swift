//
//  ArchiveFeatureComponent.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import NeedleFoundation

protocol ArchiveFeatureDependency: Dependency {}

@MainActor
final class ArchiveFeatureComponent: Component<ArchiveFeatureDependency> {
    private let quoteProvider: QuoteProvider

    init(parent: Scope, quoteProvider: QuoteProvider) {
        self.quoteProvider = quoteProvider
        super.init(parent: parent)
    }

    var viewModel: ArchiveViewModel {
        ArchiveViewModel(quoteProvider: self.quoteProvider)
    }

    func view() -> ArchiveView {
        ArchiveView(viewModel: self.viewModel)
    }
}
