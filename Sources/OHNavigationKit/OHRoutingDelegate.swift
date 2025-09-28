//
//  File.swift
//  OHNavigationKit
//
//  Created by Ariesta Agung on 27/09/25.
//

import Foundation
import SwiftUI

@MainActor
/// Public protocol your app will use to navigate.
public protocol OHRouting: AnyObject {
    associatedtype Route: Hashable & Codable
    var currentStack: [Route] { get }
    func push(_ route: Route)
    func pop()
    func popToRoot()
    func replaceStack(with routes: [Route])
    func setRoot(_ route: Route, children: [Route])
}


/// Route -> View renderer used by the routers to build screens.
public protocol OHRouteRenderer {
    associatedtype Route
    @ViewBuilder func view(for route: Route) -> AnyView
}


//public typealias OHRouteViewBuilder<Route> = (_ route: Route) -> AnyView
public typealias OHRouteViewBuilder<Route> = @MainActor (_ route: Route) -> AnyView
