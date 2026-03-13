//
//  ArchiveFeatureComponent.swift
//  RunicQuotes
//
//  Created by Codex on 2026-03-13.
//

import NeedleFoundation

protocol ArchiveFeatureDependency: Dependency { }

@MainActor
final class ArchiveFeatureComponent: Component<ArchiveFeatureDependency> {
    private let quoteProvider: QuoteProvider

    init(parent: Scope, quoteProvider: QuoteProvider) {
        self.quoteProvider = quoteProvider
        super.init(parent: parent)
    }

    var viewModel: ArchiveViewModel {
        ArchiveViewModel(quoteProvider: quoteProvider)
    }

    func view() -> ArchiveView {
        ArchiveView(viewModel: viewModel)
    }
}
