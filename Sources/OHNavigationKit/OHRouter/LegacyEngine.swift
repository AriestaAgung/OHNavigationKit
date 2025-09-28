//
//  File.swift
//  OHNavigationKit
//
//  Created by Ariesta Agung on 28/09/25.
//

import Foundation
import SwiftUI

// MARK: - iOS 13–15 UIKit engine
#if canImport(UIKit)
@MainActor
final class LegacyEngine<Route: Hashable & Codable>: NSObject, ObservableObject {
    private lazy var nav = UINavigationController() // UIKit must stay on main thread.
    private let builder: OHRouteViewBuilder<Route>
    private let envWrap: (AnyView) -> AnyView
    
    
    init(builder: @escaping OHRouteViewBuilder<Route>,
         envWrap: @escaping (AnyView) -> AnyView) {
        self.builder = builder
        self.envWrap = envWrap
        super.init()
    }
    
    @ViewBuilder
    func mountRoot(_ rootContent: @escaping () -> AnyView) -> some View {
        LegacyNavContainer {
            let rootVC = UIHostingController(rootView: self.envWrap(rootContent()))
            self.nav.setViewControllers([rootVC], animated: false)
            return self.nav
        }
    }
    
    func push(_ route: Route) {
        nav.pushViewController(makeVC(for: route), animated: true)
    }
    
    func pop() { _ = nav.popViewController(animated: true) }
    
    func popToRoot() { _ = nav.popToRootViewController(animated: true) }
    
    func replaceStack(with routes: [Route], rootContent: (() -> AnyView)) {
        var vcs: [UIViewController] = [UIHostingController(rootView: rootContent())]
        vcs.append(contentsOf: routes.map(makeVC(for:)))
        nav.setViewControllers(vcs, animated: false)
    }
    
    func setRoot(_ route: Route, children: [Route]) {
        let vcs = [makeVC(for: route)] + children.map(makeVC(for:))
        nav.setViewControllers(vcs, animated: false)
    }
    
    private func makeVC(for route: Route) -> UIViewController {
        UIHostingController(rootView: envWrap(builder(route)))
    }
}
#endif
