

import Foundation
import NeedleFoundation
import SwiftData
import SwiftUI

// swiftlint:disable unused_declaration
private let needleDependenciesHash : String? = nil

// MARK: - Traversal Helpers

private func parent1(_ component: NeedleFoundation.Scope) -> NeedleFoundation.Scope {
    return component.parent
}

// MARK: - Providers

#if !NEEDLE_DYNAMIC

private class SearchFeatureDependencye312343aefab9521cd19Provider: SearchFeatureDependency {


    init() {

    }
}
/// ^->AppRootComponent->SearchFeatureComponent
private func factory5b6926d7d46659905e20e3b0c44298fc1c149afb(_ component: NeedleFoundation.Scope) -> AnyObject {
    return SearchFeatureDependencye312343aefab9521cd19Provider()
}
private class SavedFeatureDependencye73729eafef9ca22fb1cProvider: SavedFeatureDependency {


    init() {

    }
}
/// ^->AppRootComponent->SavedFeatureComponent
private func factory921aaa366689b23dbf9ee3b0c44298fc1c149afb(_ component: NeedleFoundation.Scope) -> AnyObject {
    return SavedFeatureDependencye73729eafef9ca22fb1cProvider()
}
private class SettingsFeatureDependencyb6f25144cccb31684b26Provider: SettingsFeatureDependency {


    init() {

    }
}
/// ^->AppRootComponent->SettingsFeatureComponent
private func factory91ef58959d1a9ee25ee4e3b0c44298fc1c149afb(_ component: NeedleFoundation.Scope) -> AnyObject {
    return SettingsFeatureDependencyb6f25144cccb31684b26Provider()
}
private class CreateEditQuoteFeatureDependency34fee500c0f05b9bc59fProvider: CreateEditQuoteFeatureDependency {


    init() {

    }
}
/// ^->AppRootComponent->CreateEditQuoteFeatureComponent
private func factory02806c742bb60fdf33e8e3b0c44298fc1c149afb(_ component: NeedleFoundation.Scope) -> AnyObject {
    return CreateEditQuoteFeatureDependency34fee500c0f05b9bc59fProvider()
}
private class QuoteFeatureDependencyd768f4f6b1cc6cc18415Provider: QuoteFeatureDependency {


    init() {

    }
}
/// ^->AppRootComponent->QuoteFeatureComponent
private func factory6223a91e1d782f20e83be3b0c44298fc1c149afb(_ component: NeedleFoundation.Scope) -> AnyObject {
    return QuoteFeatureDependencyd768f4f6b1cc6cc18415Provider()
}
private class TranslationFeatureDependency4e62b0ef7a7ee4119806Provider: TranslationFeatureDependency {


    init() {

    }
}
/// ^->AppRootComponent->TranslationFeatureComponent
private func factory22230cc947af82087a1fe3b0c44298fc1c149afb(_ component: NeedleFoundation.Scope) -> AnyObject {
    return TranslationFeatureDependency4e62b0ef7a7ee4119806Provider()
}
private class ArchiveFeatureDependency69cc15f712a1c645b5d1Provider: ArchiveFeatureDependency {


    init() {

    }
}
/// ^->AppRootComponent->ArchiveFeatureComponent
private func factorybed75dcf5a3defb786f7e3b0c44298fc1c149afb(_ component: NeedleFoundation.Scope) -> AnyObject {
    return ArchiveFeatureDependency69cc15f712a1c645b5d1Provider()
}

#else
extension SearchFeatureComponent: NeedleFoundation.Registration {
    public func registerItems() {

    }
}
extension SavedFeatureComponent: NeedleFoundation.Registration {
    public func registerItems() {

    }
}
extension SettingsFeatureComponent: NeedleFoundation.Registration {
    public func registerItems() {

    }
}
extension CreateEditQuoteFeatureComponent: NeedleFoundation.Registration {
    public func registerItems() {

    }
}
extension QuoteFeatureComponent: NeedleFoundation.Registration {
    public func registerItems() {

    }
}
extension AppRootComponent: NeedleFoundation.Registration {
    public func registerItems() {


    }
}
extension TranslationFeatureComponent: NeedleFoundation.Registration {
    public func registerItems() {

    }
}
extension ArchiveFeatureComponent: NeedleFoundation.Registration {
    public func registerItems() {

    }
}


#endif

private func factoryEmptyDependencyProvider(_ component: NeedleFoundation.Scope) -> AnyObject {
    return EmptyDependencyProvider(component: component)
}

// MARK: - Registration
private func registerProviderFactory(_ componentPath: String, _ factory: @escaping (NeedleFoundation.Scope) -> AnyObject) {
    __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: componentPath, factory)
}

#if !NEEDLE_DYNAMIC

@inline(never) private func register1() {
    registerProviderFactory("^->AppRootComponent->SearchFeatureComponent", factory5b6926d7d46659905e20e3b0c44298fc1c149afb)
    registerProviderFactory("^->AppRootComponent->SavedFeatureComponent", factory921aaa366689b23dbf9ee3b0c44298fc1c149afb)
    registerProviderFactory("^->AppRootComponent->SettingsFeatureComponent", factory91ef58959d1a9ee25ee4e3b0c44298fc1c149afb)
    registerProviderFactory("^->AppRootComponent->CreateEditQuoteFeatureComponent", factory02806c742bb60fdf33e8e3b0c44298fc1c149afb)
    registerProviderFactory("^->AppRootComponent->QuoteFeatureComponent", factory6223a91e1d782f20e83be3b0c44298fc1c149afb)
    registerProviderFactory("^->AppRootComponent", factoryEmptyDependencyProvider)
    registerProviderFactory("^->AppRootComponent->TranslationFeatureComponent", factory22230cc947af82087a1fe3b0c44298fc1c149afb)
    registerProviderFactory("^->AppRootComponent->ArchiveFeatureComponent", factorybed75dcf5a3defb786f7e3b0c44298fc1c149afb)
}
#endif

public func registerProviderFactories() {
#if !NEEDLE_DYNAMIC
    register1()
#endif
}
