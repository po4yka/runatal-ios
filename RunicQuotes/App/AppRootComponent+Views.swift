//
//  AppRootComponent+Views.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import SwiftUI

extension AppRootComponent {
    func makeMainTabView() -> MainTabView {
        MainTabView(
            searchCoordinator: searchCoordinator,
            homeAccessoryController: homeAccessoryController,
            quoteView: quoteFeatureComponent.view(),
            searchView: searchFeatureComponent.view(),
            savedView: savedFeatureComponent.view(),
            settingsView: settingsFeatureComponent.view(),
        )
    }

    func makeOnboardingView(onComplete: @escaping () -> Void) -> some View {
        OnboardingView(onComplete: onComplete)
            .environment(\.userPreferencesRepository, preferencesRepository)
    }
}
