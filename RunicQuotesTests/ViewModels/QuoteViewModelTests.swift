//
//  QuoteViewModelTests.swift
//  RunicQuotes
//
//  Created by Claude on 30.10.25.
//

@testable import RunicQuotes
import SwiftData
import Testing

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
        #expect(try self.makeViewModel().state.currentScript == .elder)
    }

    @Test
    func defaultFont() throws {
        #expect(try self.makeViewModel().state.currentFont == .noto)
    }

    @Test
    func defaultCollection() throws {
        #expect(try self.makeViewModel().state.currentCollection == .all)
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
        let (viewModel, context) = try self.makeViewModelWithContext()
        let preferences = SwiftDataUserPreferencesRepository(modelContext: context)
        viewModel.onScriptChanged(.cirth)
        #expect(await TestSupport.eventually {
            viewModel.state.currentScript == .cirth && !viewModel.state.isLoading
        })
        let accepted = try preferences.snapshot()
        let quoteID = viewModel.state.currentQuoteID
        let displayed = viewModel.state.runicText
        #expect(accepted.selectedFont == .cirth)

        viewModel.onFontChanged(.noto)

        #expect(viewModel.state.errorMessage == "Failed to save preferences: The selected font does not support the current script.")
        #expect(viewModel.state.currentFont == .cirth)
        #expect(viewModel.state.currentScript == .cirth)
        #expect(viewModel.state.currentQuoteID == quoteID)
        #expect(viewModel.state.runicText == displayed)
        #expect(try preferences.snapshot().selectedFont == accepted.selectedFont)
        #expect(try preferences.snapshot().selectedScript == accepted.selectedScript)
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
            quoteID: nil,
            scriptRaw: RunicScript.younger.rawValue,
            modeRaw: WidgetMode.random.rawValue,
            collectionRaw: nil,
        )

        #expect(await TestSupport.eventually {
            viewModel.state.currentScript == .younger &&
                viewModel.state.currentReadingMode == .random &&
                !viewModel.state.isLoading
        })
        #expect(viewModel.state.currentScript == .younger)
        #expect(viewModel.state.currentReadingMode == .random)
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
        let (viewModel, modelContext) = try makeViewModelWithContext(seedData: false)
        let text = "The wolf hunts at night"
        let quote = try SwiftDataQuoteRepository(modelContext: modelContext).createQuote(
            textLatin: text, author: "Audit", source: nil, collection: .stoic,
        )
        try SwiftDataUserPreferencesRepository(modelContext: modelContext).apply([.script(.younger)])
        viewModel.onAppear()
        #expect(await TestSupport.eventually { !viewModel.state.isLoading && viewModel.state.currentQuoteID == quote.id })
        let originalRunicText = viewModel.state.runicText
        let result = HistoricalTranslationService().translate(text: text, script: .younger, fidelity: .strict)
        #expect(result.isAvailable)
        try SwiftDataTranslationRepository(modelContext: modelContext).cache(result: result, for: quote.id, sourceText: text)
        viewModel.onTranslationCacheUpdated(for: quote.id)
        #expect(await TestSupport.eventually { viewModel.state.runicText == result.glyphOutput })
        #expect(originalRunicText != viewModel.state.runicText)
        #expect(viewModel.state.runicPresentationSource == .structuredTranslation)
    }

    @Test
    func appearancePreferenceChangesFinishLoadingAndPreservePassage() async throws {
        let (viewModel, context) = try self.makeViewModelWithContext()
        viewModel.onAppear()
        #expect(await TestSupport.eventually { !viewModel.state.isLoading })
        let quoteID = viewModel.state.currentQuoteID
        let repository = SwiftDataUserPreferencesRepository(modelContext: context)
        try repository.apply([.font(.babelstone), .theme(.nordicDawn), .widgetStyle(.translationFirst), .decorativeGlyphs(false)])
        viewModel.onPreferencesChanged()
        #expect(await TestSupport.eventually { !viewModel.state.isLoading })
        #expect(viewModel.state.currentQuoteID == quoteID)
        #expect(viewModel.state.currentFont == .babelstone)
        #expect(viewModel.state.currentTheme == .nordicDawn)
        #expect(viewModel.state.errorMessage == nil)
    }

    @Test
    func preferenceReadFailureEndsLoadingAndShowsError() async throws {
        let context = try TestSupport.makeModelContext()
        let preferences = TestPreferencesRepository()
        preferences.snapshotResult = .failure(TestError(message: "Preference read failed"))
        let viewModel = QuoteViewModel(
            quoteProvider: QuoteProvider(modelContainer: context.container),
            translationProvider: TranslationProvider(modelContainer: context.container),
            preferencesRepository: preferences,
        )
        viewModel.onPreferencesChanged()
        #expect(await TestSupport.eventually { !viewModel.state.isLoading })
        #expect(viewModel.state.errorMessage?.contains("Preference read failed") == true)
    }

    @Test
    func widgetModePreferenceDoesNotChangeHomePassageOrItsReadingMode() async throws {
        let (viewModel, context) = try self.makeViewModelWithContext()
        viewModel.onAppear()
        #expect(await TestSupport.eventually { !viewModel.state.isLoading })
        let id = viewModel.state.currentQuoteID
        let mode = viewModel.state.currentReadingMode
        try SwiftDataUserPreferencesRepository(modelContext: context).apply([.widgetMode(.random)])
        viewModel.onPreferencesChanged()
        #expect(await TestSupport.eventually { !viewModel.state.isLoading })
        #expect(viewModel.state.currentQuoteID == id)
        #expect(viewModel.state.currentReadingMode == mode)
    }

    @Test
    func widgetIdentityAndTemporaryContextDoNotOverwriteGlobalPreferences() async throws {
        let context = try TestSupport.makeModelContext()
        let repository = SwiftDataQuoteRepository(modelContext: context)
        let first = try repository.createQuote(textLatin: "First passage", author: "Reader", source: nil, collection: .stoic, storedRunic: nil, translations: [])
        _ = try repository.createQuote(textLatin: "Another passage", author: "Reader", source: nil, collection: .motivation, storedRunic: nil, translations: [])
        let preferences = SwiftDataUserPreferencesRepository(modelContext: context)
        let model = QuoteViewModel(quoteProvider: QuoteProvider(modelContainer: context.container), translationProvider: TranslationProvider(modelContainer: context.container), preferencesRepository: preferences)
        model.onOpenQuoteDeepLink(quoteID: first.id, scriptRaw: RunicScript.cirth.rawValue, modeRaw: WidgetMode.random.rawValue, collectionRaw: QuoteCollection.stoic.rawValue)
        #expect(await TestSupport.eventually { !model.state.isLoading })
        #expect(model.state.currentQuoteID == first.id)
        #expect(model.state.currentScript == .cirth)
        #expect(model.state.currentFont.isCompatible(with: .cirth))
        #expect(try preferences.snapshot().selectedScript == .elder)
        #expect(try preferences.snapshot().selectedCollection == .all)
        #expect(try preferences.snapshot().widgetMode == .daily)
    }

    private func makeViewModel(seedData: Bool = true) throws -> QuoteViewModel {
        try self.makeViewModelWithContext(seedData: seedData).0
    }

    private func makeViewModelWithContext(seedData: Bool = true) throws -> (QuoteViewModel, ModelContext) {
        let context = try TestSupport.makeModelContext()

        if seedData {
            _ = try TestSupport.makeSeededRepository(in: context)
        }

        return (
            QuoteViewModel(
                quoteProvider: QuoteProvider(modelContainer: context.container),
                translationProvider: TranslationProvider(modelContainer: context.container),
                preferencesRepository: SwiftDataUserPreferencesRepository(modelContext: context),
            ),
            context,
        )
    }
}
