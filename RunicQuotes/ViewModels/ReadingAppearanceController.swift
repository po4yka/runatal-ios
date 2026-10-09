//
//  ReadingAppearanceController.swift
//  RunicQuotes
//
//  Created by Claude on 09.10.26.
//

import Combine
import Foundation

@MainActor
final class ReadingAppearanceController: ObservableObject {
    private struct State {
        var script: RunicScript = .elder
        var font: RunicFont = .noto
        var inputs: [UUID: RunicPresentationInput] = [:]
        var presentations: [UUID: ResolvedRunicPresentation] = [:]
        var errorMessage: String?
    }

    @Published private var state = State()
    var script: RunicScript {
        self.state.script
    }

    var font: RunicFont {
        self.state.font
    }

    private let repository: any UserPreferencesRepository
    private let quotes: any ReadingLibraryProviding
    private let translations: any ReadingTranslationsProviding
    private var observation: AnyCancellable?
    private var loadTask: Task<Void, Never>?
    private var needsRefresh = false

    init(repository: any UserPreferencesRepository, quotes: any ReadingLibraryProviding, translations: any ReadingTranslationsProviding) {
        self.repository = repository
        self.quotes = quotes
        self.translations = translations
        self.refresh()
        self.observation = NotificationCenter.default.publisher(for: .preferencesDidChange)
            .merge(with: NotificationCenter.default.publisher(for: .libraryDidChange))
            .merge(with: NotificationCenter.default.publisher(for: .translationCacheUpdated))
            .receive(on: RunLoop.main)
            .throttle(for: .milliseconds(150), scheduler: RunLoop.main, latest: true)
            .sink { [weak self] _ in Task { @MainActor in self?.refresh() } }
    }

    func presentation(for quote: QuoteRecord) -> ResolvedRunicPresentation {
        let cached = self.state.errorMessage == nil && self.state.inputs[quote.id] == RunicPresentationInput(quote: quote, script: self.script) ? self.state.presentations[quote.id] : nil
        if let cached {
            return cached
        }
        var fallback = RunicPresentationResolver.resolve(RunicPresentationInput(quote: quote, script: self.script), currentCache: nil)
        if self.state.errorMessage != nil {
            fallback.warnings.append("Current translation evidence could not be loaded.")
        }
        return fallback
    }

    private func refresh() {
        guard self.loadTask == nil else { self.needsRefresh = true; return }
        self.loadTask = Task { [self] in
            defer {
                self.loadTask = nil
                if self.needsRefresh {
                    self.needsRefresh = false
                    Task { @MainActor [weak self] in self?.refresh() }
                }
            }
            do {
                let preferences = try self.repository.snapshot()
                let allQuotes = try await self.quotes.readingLibraryQuotes()
                let cached = try await self.translations.latestTranslations(for: allQuotes.map(\.id), script: preferences.selectedScript)
                try Task.checkCancellation()
                let current = try self.repository.snapshot()
                guard current.selectedScript == preferences.selectedScript, current.selectedFont == preferences.selectedFont else {
                    self.needsRefresh = true
                    return
                }
                var next = State()
                next.script = preferences.selectedScript
                next.font = preferences.selectedFont.isCompatible(with: next.script) ? preferences.selectedFont : RunicFontConfiguration.recommendedFont(for: next.script)
                next.inputs = Dictionary(uniqueKeysWithValues: allQuotes.map { ($0.id, RunicPresentationInput(quote: $0, script: next.script)) })
                next.presentations = Dictionary(uniqueKeysWithValues: allQuotes.map { quote in
                    (quote.id, RunicPresentationResolver.resolve(RunicPresentationInput(quote: quote, script: next.script), currentCache: cached[quote.id]))
                })
                self.state = next
            } catch is CancellationError {
            } catch {
                self.state.errorMessage = error.localizedDescription
            }
        }
    }

    static func preview() -> ReadingAppearanceController {
        let container = ModelContainerHelper.createPlaceholderContainer()
        return ReadingAppearanceController(
            repository: PreviewUserPreferencesRepository.shared,
            quotes: QuoteProvider(modelContainer: container),
            translations: TranslationProvider(modelContainer: container),
        )
    }
}
