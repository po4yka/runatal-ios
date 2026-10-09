//
//  AppRootComponent.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import Foundation
import NeedleFoundation
import SwiftData

@MainActor
final class AppRootComponent: BootstrapComponent {
    let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        super.init()
    }

    var widgetRefreshCoordinator: WidgetRefreshCoordinator {
        shared { WidgetRefreshCoordinator(reloader: SystemWidgetReloader()) }
    }

    var preferencesRepository: SwiftDataUserPreferencesRepository {
        let modelContext = self.modelContainer.mainContext
        return shared {
            SwiftDataUserPreferencesRepository(modelContext: modelContext)
        }
    }

    var translationService: HistoricalTranslationService {
        shared {
            HistoricalTranslationService()
        }
    }

    var quoteRepository: SwiftDataQuoteRepository {
        let modelContext = self.modelContainer.mainContext
        return shared {
            SwiftDataQuoteRepository(
                modelContext: modelContext,
            )
        }
    }

    var quoteProvider: QuoteProvider {
        shared {
            QuoteProvider(modelContainer: self.modelContainer)
        }
    }

    var translationProvider: TranslationProvider {
        shared {
            TranslationProvider(modelContainer: self.modelContainer)
        }
    }

    var searchCoordinator: AppSearchCoordinator {
        shared {
            AppSearchCoordinator(
                query: ProcessInfo.processInfo.environment["UI_TEST_SEARCH_QUERY"] ?? "",
            )
        }
    }

    var homeAccessoryController: HomeAccessoryController {
        shared {
            HomeAccessoryController()
        }
    }

    var databaseCoordinator: DatabaseCoordinator {
        shared {
            DatabaseCoordinator(
                modelContainer: self.modelContainer,
                translationService: self.translationService,
            )
        }
    }

    var createEditQuoteViewBuilder: CreateEditQuoteViewBuilder {
        shared {
            CreateEditQuoteViewBuilder { mode, onSaved in
                CreateEditQuoteFeatureComponent(
                    parent: self,
                    quoteRepository: self.quoteRepository,
                    mode: mode,
                    onSaved: onSaved,
                ).view()
            }
        }
    }

    var translationViewBuilder: TranslationViewBuilder {
        shared {
            TranslationViewBuilder {
                TranslationFeatureComponent(
                    parent: self,
                    quoteRepository: self.quoteRepository,
                    preferencesRepository: self.preferencesRepository,
                    translationService: self.translationService,
                ).view()
            }
        }
    }

    var archiveViewBuilder: ArchiveViewBuilder {
        shared {
            ArchiveViewBuilder {
                ArchiveFeatureComponent(parent: self, quoteProvider: self.quoteProvider).view()
            }
        }
    }

    var quoteFeatureComponent: QuoteFeatureComponent {
        shared {
            QuoteFeatureComponent(
                parent: self,
                quoteProvider: self.quoteProvider,
                translationProvider: self.translationProvider,
                preferencesRepository: self.preferencesRepository,
                createEditQuoteViewBuilder: self.createEditQuoteViewBuilder,
                translationViewBuilder: self.translationViewBuilder,
            )
        }
    }

    var searchFeatureComponent: SearchFeatureComponent {
        shared {
            SearchFeatureComponent(parent: self, quoteProvider: self.quoteProvider)
        }
    }

    var savedFeatureComponent: SavedFeatureComponent {
        shared {
            SavedFeatureComponent(
                parent: self,
                quoteProvider: self.quoteProvider,
                preferencesRepository: self.preferencesRepository,
            )
        }
    }

    var settingsFeatureComponent: SettingsFeatureComponent {
        shared {
            SettingsFeatureComponent(
                parent: self,
                preferencesRepository: self.preferencesRepository,
                translationViewBuilder: self.translationViewBuilder,
                archiveViewBuilder: self.archiveViewBuilder,
            )
        }
    }
}
