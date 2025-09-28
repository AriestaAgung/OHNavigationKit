//
//  File.swift
//  OHNavigationKit
//
//  Created by Ariesta Agung on 27/09/25.
//

import Foundation
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

@MainActor
public final class OHRouter<Route: Hashable & Codable>: ObservableObject, OHRouting {

    // MARK: Public state
    @Published private(set) public var currentStack: [Route] = []

    // MARK: Internal plumbing
    private let builder: OHRouteViewBuilder<Route>
    private var rootContent: (() -> AnyView)?
    private var engineBox: AnyObject? // holds either StackEngine<Route> or LegacyEngine<Route>

    public init(builder: @escaping OHRouteViewBuilder<Route>) {
        self.builder = builder
    }

    // MARK: Mount root once and let the router choose the engine
    @ViewBuilder
    public func root<Root: View>(@ViewBuilder _ content: @escaping () -> Root) -> some View {
        if #available(iOS 16, *) {
            StackRootView(
                engine: obtainStackEngine(),
                router: self,
                rootContent: { AnyView(content()) } // pass as escaping closure
            )
            .onAppear {
                self.rootContent = { AnyView(content()) } // persist for legacy stack resets
            }
        } else {
            #if canImport(UIKit)
            obtainLegacyEngine()
                .mountRoot({ AnyView(content()) })
                .onAppear { self.rootContent = { AnyView(content()) } }
            #else
            EmptyView()
            #endif
        }
    }

    // MARK: OHRouting
    public func push(_ route: Route) {
        if #available(iOS 16, *) {
            let e = (engineBox as? StackEngine<Route>) ?? obtainStackEngine()
            e.push(route)
        } else {
            #if canImport(UIKit)
            let e = (engineBox as? LegacyEngine<Route>) ?? obtainLegacyEngine()
            e.push(route)
            #endif
        }
        currentStack.append(route)
    }

    public func pop() {
        guard !currentStack.isEmpty else { return }
        if #available(iOS 16, *) {
            (engineBox as? StackEngine<Route>)?.pop()
        } else {
            #if canImport(UIKit)
            (engineBox as? LegacyEngine<Route>)?.pop()
            #endif
        }
        currentStack.removeLast()
    }

    public func popToRoot() {
        if #available(iOS 16, *) {
            (engineBox as? StackEngine<Route>)?.popToRoot()
        } else {
            #if canImport(UIKit)
            (engineBox as? LegacyEngine<Route>)?.popToRoot()
            #endif
        }
        currentStack.removeAll()
    }

    public func replaceStack(with routes: [Route]) {
        if #available(iOS 16, *) {
            let e = (engineBox as? StackEngine<Route>) ?? obtainStackEngine()
            e.replaceStack(with: routes)
        } else {
            #if canImport(UIKit)
            let e = (engineBox as? LegacyEngine<Route>) ?? obtainLegacyEngine()
            e.replaceStack(with: routes, rootContent: rootContent ?? { AnyView(EmptyView()) })
            #endif
        }
        currentStack = routes
    }

    public func setRoot(_ route: Route, children: [Route]) {
        if #available(iOS 16, *) {
            // Root is the NavigationStack content; only children live in the path.
            let e = (engineBox as? StackEngine<Route>) ?? obtainStackEngine()
            e.replaceStack(with: children)
            currentStack = children
        } else {
            #if canImport(UIKit)
            let e = (engineBox as? LegacyEngine<Route>) ?? obtainLegacyEngine()
            e.setRoot(route, children: children)
            currentStack = Array(([route] + children).dropFirst())
            #endif
        }
    }

    // Called by the SwiftUI engine when user swipes back; keeps mirror in sync.
    func _syncAfterPathCountChange(_ newCount: Int) {
        if newCount < currentStack.count {
            currentStack.removeLast(currentStack.count - newCount)
        }
    }

    // MARK: Engine creation (no @available on stored properties)
    @available(iOS 16, *)
    private func obtainStackEngine() -> StackEngine<Route> {
        if let e = engineBox as? StackEngine<Route> { return e }
        let e = StackEngine<Route>(builder: builder)
        engineBox = e
        return e
    }

    #if canImport(UIKit)
    private func obtainLegacyEngine() -> LegacyEngine<Route> {
        if let e = engineBox as? LegacyEngine<Route> { return e }
        // wrap every SwiftUI root with .environmentObject(self)
        let e = LegacyEngine<Route>(
            builder: builder,
            envWrap: { [weak self] view in
                guard let self = self else { return view }
                return AnyView(view.environmentObject(self))
            }
        )
        engineBox = e
        return e
    }
    #endif
}

public extension OHRouter where Route == AnyRoute {
  @MainActor
  func push<R: FeatureRoute>(_ route: R) {
    R.ensureRegistered()           // 🔑 make sure builder/encoders exist
    push(AnyRoute(route))
  }

  @MainActor
  func replaceStack<R: FeatureRoute>(with routes: [R]) {
    if let first = routes.first { type(of: first).ensureRegistered() }
    replaceStack(with: routes.map(AnyRoute.init))
  }

  @MainActor
  func setRoot<R: FeatureRoute>(_ route: R, children: [R] = []) {
    R.ensureRegistered()
    setRoot(AnyRoute(route), children: children.map(AnyRoute.init))
  }
}

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

@available(iOS 16, *)
struct StackRootView<Route: Hashable & Codable>: View {
    @ObservedObject var engine: StackEngine<Route>
    @ObservedObject var router: OHRouter<Route>
    let rootContent: () -> AnyView

    var body: some View {
        NavigationStack(path: $engine.path) {
            rootContent()
                .navigationDestination(for: Route.self) { engine.destination(for: $0) }
        }
        // Keep router.currentStack in sync when user swipes back.
        .onChange(of: engine.path.count) { router._syncAfterPathCountChange($0) }
    }
}

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

@MainActor
private struct LegacyNavContainer: UIViewControllerRepresentable {
    let provider: () -> UINavigationController
    init(_ provider: @escaping () -> UINavigationController) { self.provider = provider }

    func makeUIViewController(context: Context) -> UIViewController { provider() }
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
#endif
