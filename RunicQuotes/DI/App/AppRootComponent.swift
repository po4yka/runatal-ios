//
//  AppRootComponent.swift
//  RunicQuotes
//
//  Created by Codex on 2026-03-13.
//

import NeedleFoundation
import SwiftData

@MainActor
final class AppRootComponent: BootstrapComponent {
    let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        super.init()
    }

    var preferencesRepository: SwiftDataUserPreferencesRepository {
        let modelContext = modelContainer.mainContext
        return shared {
            SwiftDataUserPreferencesRepository(modelContext: modelContext)
        }
    }

    var translationService: HistoricalTranslationService {
        return shared {
            HistoricalTranslationService()
        }
    }

    var translationRepository: SwiftDataTranslationRepository {
        let modelContext = modelContainer.mainContext
        let translationService = self.translationService
        return shared {
            SwiftDataTranslationRepository(
                modelContext: modelContext,
                translationService: translationService
            )
        }
    }

    var quoteRepository: SwiftDataQuoteRepository {
        let modelContext = modelContainer.mainContext
        let translationRepository = self.translationRepository
        return shared {
            SwiftDataQuoteRepository(
                modelContext: modelContext,
                translationCacheRepository: translationRepository
            )
        }
    }

    var quoteProvider: QuoteProvider {
        return shared {
            QuoteProvider(repository: quoteRepository)
        }
    }

    var translationProvider: TranslationProvider {
        return shared {
            TranslationProvider(repository: translationRepository)
        }
    }

    var searchCoordinator: AppSearchCoordinator {
        return shared {
            AppSearchCoordinator()
        }
    }

    var homeAccessoryController: HomeAccessoryController {
        return shared {
            HomeAccessoryController()
        }
    }

    var databaseCoordinator: DatabaseCoordinator {
        return shared {
            DatabaseCoordinator(
                modelContainer: modelContainer,
                translationService: translationService
            )
        }
    }

    var createEditQuoteViewBuilder: CreateEditQuoteViewBuilder {
        return shared {
            CreateEditQuoteViewBuilder { mode, onSaved in
                CreateEditQuoteFeatureComponent(
                    parent: self,
                    quoteRepository: self.quoteRepository,
                    mode: mode,
                    onSaved: onSaved
                ).view()
            }
        }
    }

    var translationViewBuilder: TranslationViewBuilder {
        return shared {
            TranslationViewBuilder {
                TranslationFeatureComponent(
                    parent: self,
                    quoteRepository: self.quoteRepository,
                    translationRepository: self.translationRepository,
                    preferencesRepository: self.preferencesRepository,
                    translationService: self.translationService
                ).view()
            }
        }
    }

    var archiveViewBuilder: ArchiveViewBuilder {
        return shared {
            ArchiveViewBuilder {
                ArchiveFeatureComponent(parent: self, quoteProvider: self.quoteProvider).view()
            }
        }
    }

    var quoteFeatureComponent: QuoteFeatureComponent {
        return shared {
            QuoteFeatureComponent(
                parent: self,
                quoteProvider: self.quoteProvider,
                translationProvider: self.translationProvider,
                preferencesRepository: self.preferencesRepository,
                createEditQuoteViewBuilder: self.createEditQuoteViewBuilder,
                translationViewBuilder: self.translationViewBuilder
            )
        }
    }

    var searchFeatureComponent: SearchFeatureComponent {
        return shared {
            SearchFeatureComponent(parent: self, quoteProvider: self.quoteProvider)
        }
    }

    var savedFeatureComponent: SavedFeatureComponent {
        return shared {
            SavedFeatureComponent(
                parent: self,
                quoteProvider: self.quoteProvider,
                preferencesRepository: self.preferencesRepository
            )
        }
    }

    var settingsFeatureComponent: SettingsFeatureComponent {
        return shared {
            SettingsFeatureComponent(
                parent: self,
                preferencesRepository: self.preferencesRepository,
                translationViewBuilder: self.translationViewBuilder,
                archiveViewBuilder: self.archiveViewBuilder
            )
        }
    }
}
