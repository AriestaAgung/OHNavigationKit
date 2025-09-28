//
//  File.swift
//  OHNavigationKit
//
//  Created by Ariesta Agung on 27/09/25.
//

import SwiftUI

@MainActor
@available(iOS 16, *)
public final class StackRouter<T: Route>: ObservableObject, OHRouting {
    @Published public var path = NavigationPath()
    private let builder: OHRouteViewBuilder<T>
    private var stack: [T] = []
    
    // ✅ No root required on iOS 16+
    public init(builder: @escaping OHRouteViewBuilder<T>) {
        self.builder = builder
    }
    
    public var currentStack: [T] { stack }
    
    public func push(_ route: T) {
        stack.append(route)
        path.append(route)
    }
    
    public func pop() {
        guard !stack.isEmpty else { return }
        stack.removeLast()
        path.removeLast()
    }
    
    public func popToRoot() {
        stack.removeAll()
        path = NavigationPath()
    }
    
    public func replaceStack(with routes: [T]) {
        stack = routes
        path = NavigationPath(routes)
    }
    
    public func setRoot(_ route: T, children: [T]) {
        // Root is the NavigationStack content; only children belong in the path.
        replaceStack(with: children)
    }
    
    // Build SwiftUI view for a given route
    @ViewBuilder
    func destinationView(for route: T) -> some View { builder(route) }
}
