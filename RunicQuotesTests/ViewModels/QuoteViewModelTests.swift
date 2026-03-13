//
//  QuoteViewModelTests.swift
//  RunicQuotes
//
//  Created by Claude on 30.10.25.
//

import SwiftData
import Testing
@testable import RunicQuotes

@MainActor
@Suite(.serialized, .tags(.viewModel))
struct QuoteViewModelTests {
    @Test
    func initialState() throws {
        let viewModel = try makeViewModel()

        #expect(viewModel.state.isLoading)
        #expect(viewModel.state.runicText.isEmpty)
        #expect(viewModel.state.latinText.isEmpty)
        #expect(viewModel.state.author.isEmpty)
    }

    @Test
    func defaultScript() throws {
        #expect(try makeViewModel().state.currentScript == .elder)
    }

    @Test
    func defaultFont() throws {
        #expect(try makeViewModel().state.currentFont == .noto)
    }

    @Test
    func defaultCollection() throws {
        #expect(try makeViewModel().state.currentCollection == .all)
    }

    @Test
    func onAppearLoadsQuote() async throws {
        let viewModel = try makeViewModel()
        viewModel.onAppear()

        #expect(await TestSupport.eventually { !viewModel.state.isLoading })
        #expect(!viewModel.state.latinText.isEmpty)
        #expect(!viewModel.state.author.isEmpty)
    }

    @Test
    func loadedQuoteHasRunicText() async throws {
        let viewModel = try makeViewModel()
        viewModel.onAppear()

        #expect(await TestSupport.eventually { !viewModel.state.isLoading })
        #expect(!viewModel.state.runicText.isEmpty)
        #expect(viewModel.state.runicText != viewModel.state.latinText)
    }

    @Test
    func scriptChangeUpdatesState() async throws {
        let viewModel = try makeViewModel()
        viewModel.onAppear()
        #expect(await TestSupport.eventually { !viewModel.state.isLoading })

        viewModel.onScriptChanged(.younger)

        #expect(await TestSupport.eventually {
            viewModel.state.currentScript == .younger && !viewModel.state.isLoading
        })
        #expect(viewModel.state.currentScript == .younger)
    }

    @Test
    func scriptChangeReloadsQuote() async throws {
        let viewModel = try makeViewModel()
        viewModel.onAppear()
        #expect(await TestSupport.eventually { !viewModel.state.isLoading })

        let originalText = viewModel.state.latinText
        viewModel.onScriptChanged(.cirth)

        #expect(await TestSupport.eventually {
            viewModel.state.currentScript == .cirth && !viewModel.state.isLoading
        })
        #expect(!viewModel.state.latinText.isEmpty)
        #expect(!originalText.isEmpty)
    }

    @Test
    func fontChangeUpdatesState() async throws {
        let viewModel = try makeViewModel()
        viewModel.onAppear()
        #expect(await TestSupport.eventually { !viewModel.state.isLoading })

        viewModel.onFontChanged(.babelstone)

        #expect(await TestSupport.eventually { viewModel.state.currentFont == .babelstone })
        #expect(viewModel.state.currentFont == .babelstone)
    }

    @Test
    func fontCompatibilityCheck() async throws {
        let viewModel = try makeViewModel()
        viewModel.onScriptChanged(.cirth)

        #expect(await TestSupport.eventually {
            viewModel.state.currentScript == .cirth && !viewModel.state.isLoading
        })

        viewModel.onFontChanged(.noto)

        #expect(await TestSupport.eventually {
            viewModel.state.errorMessage != nil || viewModel.state.currentFont != .noto
        })

        if let errorMessage = viewModel.state.errorMessage {
            #expect(errorMessage.contains("compatible"))
        }
    }

    @Test
    func nextQuoteTappedLoadsQuote() async throws {
        let viewModel = try makeViewModel()
        viewModel.onAppear()
        #expect(await TestSupport.eventually { !viewModel.state.isLoading })

        viewModel.onNextQuoteTapped()

        #expect(await TestSupport.eventually {
            !viewModel.state.isLoading && !viewModel.state.latinText.isEmpty && !viewModel.state.author.isEmpty
        })
        #expect(!viewModel.state.latinText.isEmpty)
        #expect(!viewModel.state.author.isEmpty)
    }

    @Test
    func collectionChangeLoadsQuoteFromCollection() async throws {
        let viewModel = try makeViewModel()
        viewModel.onAppear()
        #expect(await TestSupport.eventually { !viewModel.state.isLoading })

        viewModel.onCollectionChanged(.tolkien)

        #expect(await TestSupport.eventually {
            viewModel.state.currentCollection == .tolkien && !viewModel.state.isLoading
        })

        let currentQuote = try #require(viewModel.currentQuoteRecord())
        #expect(currentQuote.collection == .tolkien)
    }

    @Test
    func toggleSaveUpdatesState() async throws {
        let viewModel = try makeViewModel()
        viewModel.onAppear()

        #expect(await TestSupport.eventually {
            !viewModel.state.isLoading && viewModel.state.currentQuoteID != nil
        })
        #expect(!viewModel.state.isCurrentQuoteSaved)

        viewModel.onToggleSaveTapped()
        #expect(await TestSupport.eventually { viewModel.state.isCurrentQuoteSaved })

        viewModel.onToggleSaveTapped()
        #expect(await TestSupport.eventually { !viewModel.state.isCurrentQuoteSaved })
    }

    @Test
    func deepLinkAppliesScriptAndModeContext() async throws {
        let viewModel = try makeViewModel()
        viewModel.onAppear()
        #expect(await TestSupport.eventually { !viewModel.state.isLoading })

        viewModel.onOpenQuoteDeepLink(
            scriptRaw: RunicScript.younger.rawValue,
            modeRaw: WidgetMode.random.rawValue
        )

        #expect(await TestSupport.eventually {
            viewModel.state.currentScript == .younger &&
                viewModel.state.currentWidgetMode == .random &&
                !viewModel.state.isLoading
        })
        #expect(viewModel.state.currentScript == .younger)
        #expect(viewModel.state.currentWidgetMode == .random)
        #expect(!viewModel.state.latinText.isEmpty)
    }

    @Test
    func refreshReloadsQuote() async throws {
        let viewModel = try makeViewModel()
        viewModel.onAppear()
        #expect(await TestSupport.eventually { !viewModel.state.isLoading })

        viewModel.refresh()

        #expect(await TestSupport.eventually { !viewModel.state.isLoading })
        #expect(!viewModel.state.latinText.isEmpty)
        #expect(viewModel.state.errorMessage == nil)
    }

    @Test
    func errorStateWhenNoQuotes() async throws {
        let viewModel = try makeViewModel(seedData: false)
        viewModel.onAppear()

        #expect(await TestSupport.eventually {
            !viewModel.state.isLoading && viewModel.state.errorMessage != nil
        })
        #expect(viewModel.state.errorMessage != nil)
        #expect(!viewModel.state.isLoading)
    }

    @Test
    func stateConsistencyAfterMultipleOperations() async throws {
        let viewModel = try makeViewModel()
        viewModel.onAppear()
        #expect(await TestSupport.eventually { !viewModel.state.isLoading })

        viewModel.onScriptChanged(.younger)
        #expect(await TestSupport.eventually {
            viewModel.state.currentScript == .younger && !viewModel.state.isLoading
        })

        viewModel.onFontChanged(.babelstone)
        #expect(await TestSupport.eventually { viewModel.state.currentFont == .babelstone })

        viewModel.onNextQuoteTapped()
        #expect(await TestSupport.eventually { !viewModel.state.isLoading })

        #expect(viewModel.state.currentScript == .younger)
        #expect(viewModel.state.currentFont == .babelstone)
        #expect(!viewModel.state.latinText.isEmpty)
    }

    @Test
    func structuredTranslationIsPreferredWhenCacheUpdates() async throws {
        let (viewModel, modelContext) = try makeViewModelWithContext()
        viewModel.onAppear()

        #expect(await TestSupport.eventually {
            !viewModel.state.isLoading && viewModel.state.currentQuoteID != nil
        })

        let quoteID = try #require(viewModel.state.currentQuoteID)
        let originalRunicText = viewModel.state.runicText
        let translationRepository = SwiftDataTranslationRepository(modelContext: modelContext)
        try translationRepository.cache(
            result: TranslationResult(
                sourceText: viewModel.state.latinText,
                script: .elder,
                fidelity: .strict,
                derivationKind: .goldExample,
                historicalStage: .oldNorse,
                normalizedForm: "normalized",
                diplomaticForm: "diplomatic",
                glyphOutput: "ᛏᛖᛋᛏ",
                resolutionStatus: .reconstructed,
                confidence: 0.9,
                notes: [],
                unresolvedTokens: [],
                provenance: [],
                tokenBreakdown: [],
                engineVersion: "test-engine",
                datasetVersion: "test-dataset"
            ),
            for: quoteID,
            sourceText: viewModel.state.latinText
        )

        viewModel.onTranslationCacheUpdated(for: quoteID)

        #expect(await TestSupport.eventually { viewModel.state.runicText == "ᛏᛖᛋᛏ" })
        #expect(originalRunicText != viewModel.state.runicText)
        #expect(viewModel.state.runicPresentationSource == .structuredTranslation)
    }

    private func makeViewModel(seedData: Bool = true) throws -> QuoteViewModel {
        try makeViewModelWithContext(seedData: seedData).0
    }

    private func makeViewModelWithContext(seedData: Bool = true) throws -> (QuoteViewModel, ModelContext) {
        let context = try TestSupport.makeModelContext()

        if seedData {
            _ = try TestSupport.makeSeededRepository(in: context)
        }

        let translationRepository = SwiftDataTranslationRepository(modelContext: context)
        return (
            QuoteViewModel(
                quoteProvider: QuoteProvider(
                    repository: SwiftDataQuoteRepository(
                        modelContext: context,
                        translationCacheRepository: translationRepository
                    )
                ),
                translationProvider: TranslationProvider(repository: translationRepository),
                preferencesRepository: SwiftDataUserPreferencesRepository(modelContext: context)
            ),
            context
        )
    }
}
