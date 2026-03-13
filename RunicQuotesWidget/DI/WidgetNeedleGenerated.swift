//
//  WidgetNeedleGenerated.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import NeedleFoundation
import SwiftData

// swiftlint:disable unused_declaration
private let needleDependenciesHash: String? = nil

// MARK: - Traversal Helpers

private func parent1(_ component: NeedleFoundation.Scope) -> NeedleFoundation.Scope {
    component.parent
}

// MARK: - Providers

#if !NEEDLE_DYNAMIC

#else
    extension WidgetRootComponent: NeedleFoundation.Registration {
        public func registerItems() {}
    }

#endif

private func factoryEmptyDependencyProvider(_ component: NeedleFoundation.Scope) -> AnyObject {
    EmptyDependencyProvider(component: component)
}

// MARK: - Registration
private func registerProviderFactory(_ componentPath: String, _ factory: @escaping (NeedleFoundation.Scope) -> AnyObject) {
    __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: componentPath, factory)
}

#if !NEEDLE_DYNAMIC

    @inline(never) private func register1() {
        registerProviderFactory("^->WidgetRootComponent", factoryEmptyDependencyProvider)
    }
#endif

public func registerProviderFactories() {
    #if !NEEDLE_DYNAMIC
        register1()
    #endif
}
