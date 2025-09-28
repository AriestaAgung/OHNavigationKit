//
//  File.swift
//  OHNavigationKit
//
//  Created by Ariesta Agung on 28/09/25.
//

import Foundation
import SwiftUI

// MARK: - iOS 16+ SwiftUI engine
@available(iOS 16, *)
@MainActor
final class StackEngine<Route: Hashable & Codable>: ObservableObject {
    @Published var path = NavigationPath()
    private let builder: OHRouteViewBuilder<Route>

    init(builder: @escaping OHRouteViewBuilder<Route>) {
        self.builder = builder
    }

    func push(_ route: Route) { path.append(route) }
    func pop() { if path.count > 0 { path.removeLast() } }
    func popToRoot() { path = NavigationPath() }
    func replaceStack(with routes: [Route]) { path = NavigationPath(routes) }

    @ViewBuilder
    func destination(for route: Route) -> some View { builder(route) }
}

