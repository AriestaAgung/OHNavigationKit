//
//  File.swift
//  OHNavigationKit
//
//  Created by Ariesta Agung on 28/09/25.
//

import Foundation
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - iOS 13–15 UIKit engine

#if canImport(UIKit)
@MainActor
final class LegacyEngine<Route: Hashable & Codable>: NSObject, ObservableObject, UIGestureRecognizerDelegate, UINavigationControllerDelegate {

    private lazy var nav = UINavigationController() // UIKit must stay on main thread.
    private let builder: OHRouteViewBuilder<Route>
    private let envWrap: (AnyView) -> AnyView

    // Keep a light proxy to know the top route for back handling.
    private final class OHHostingController: UIHostingController<AnyView> {
        var anyRoute: AnyRoute?
    }

    // Baseline (default) appearance to restore when style is nil
    private var baselineAppearance: UINavigationBarAppearance!
    private var baselinePrefersLargeTitles: Bool = false
    private var baselineTintColor: UIColor?

    init(builder: @escaping OHRouteViewBuilder<Route>,
         envWrap: @escaping (AnyView) -> AnyView) {
        self.builder = builder
        self.envWrap = envWrap
        super.init()

        // Capture defaults (UINavigationBarAppearance is iOS 13+)
        baselineAppearance = nav.navigationBar.standardAppearance
        baselinePrefersLargeTitles = nav.navigationBar.prefersLargeTitles
        baselineTintColor = nav.navigationBar.tintColor

        // Observe transitions + manage swipe-back
        nav.delegate = self
        nav.interactivePopGestureRecognizer?.delegate = self
    }

    @ViewBuilder
    func mountRoot(_ rootContent: @escaping () -> AnyView) -> some View {
        LegacyNavContainer({
            let rootVC = UIHostingController(rootView: self.envWrap(rootContent()))
            self.nav.setViewControllers([rootVC], animated: false)
            return self.nav
        })
    }

    func push(_ route: Route) {
        let vc = makeVC(for: route)
        applyStyle(for: AnyRoute(route), to: vc)
        nav.pushViewController(vc, animated: true)
    }

    func pop() { _ = nav.popViewController(animated: true) }

    func popToRoot() { _ = nav.popToRootViewController(animated: true) }

    func replaceStack(with routes: [Route], rootContent: (() -> AnyView)) {
        var vcs: [UIViewController] = [UIHostingController(rootView: rootContent())]
        vcs.append(contentsOf: routes.map { r in
            let vc = makeVC(for: r)
            applyStyle(for: AnyRoute(r), to: vc)
            return vc
        })
        nav.setViewControllers(vcs, animated: false)
        if let top = vcs.last as? OHHostingController, let any = top.anyRoute {
            applyBarAppearance(for: any)
        } else {
            restoreBaselineAppearance()
        }
    }

    func setRoot(_ route: Route, children: [Route]) {
        var vcs: [UIViewController] = [makeVC(for: route)]
        vcs.append(contentsOf: children.map(makeVC(for:)))
        // Apply styles per VC
        for vc in vcs {
            if let hc = vc as? OHHostingController, let any = hc.anyRoute {
                applyStyle(for: any, to: hc)
            }
        }
        nav.setViewControllers(vcs, animated: false)
        if let top = vcs.last as? OHHostingController, let any = top.anyRoute {
            applyBarAppearance(for: any)
        } else {
            restoreBaselineAppearance()
        }
    }

    private func makeVC(for route: Route) -> UIViewController {
        let view = envWrap(builder(route))
        let vc = OHHostingController(rootView: view)
        vc.anyRoute = AnyRoute(route)
        return vc
    }

    // MARK: - Styling / Back handling

    private func applyStyle(for any: AnyRoute, to vc: UIViewController) {
        if let title = RouteRegistry.shared.title(for: any) {
            vc.title = title
        }
        applyBarAppearance(for: any)
        applyCustomBackIfNeeded(for: any, to: vc)
    }

    private func applyBarAppearance(for any: AnyRoute) {
        if let st = RouteRegistry.shared.style(for: any) {
            let a = UINavigationBarAppearance()
            a.configureWithOpaqueBackground() // solid color background
            if let bg = st.backgroundColor { a.backgroundColor = bg }
            if let tc = st.titleColor {
                a.titleTextAttributes = [.foregroundColor: tc]
                a.largeTitleTextAttributes = [.foregroundColor: tc]
            }
            nav.navigationBar.prefersLargeTitles = st.prefersLargeTitles
            if let tint = st.tintColor { nav.navigationBar.tintColor = tint }
            nav.navigationBar.standardAppearance = a
            nav.navigationBar.scrollEdgeAppearance = a
            nav.navigationBar.compactAppearance = a
        } else {
            restoreBaselineAppearance()
        }
    }

    private func restoreBaselineAppearance() {
        nav.navigationBar.prefersLargeTitles = baselinePrefersLargeTitles
        nav.navigationBar.tintColor = baselineTintColor
        nav.navigationBar.standardAppearance = baselineAppearance
        nav.navigationBar.scrollEdgeAppearance = baselineAppearance
        nav.navigationBar.compactAppearance = baselineAppearance
    }

    private func applyCustomBackIfNeeded(for any: AnyRoute, to vc: UIViewController) {
        guard let backAction = RouteRegistry.shared.style(for: any)?.backAction else {
            // default back behavior
            vc.navigationItem.hidesBackButton = false
            vc.navigationItem.leftBarButtonItem = nil
            return
        }
        // Replace default back with custom action
        vc.navigationItem.hidesBackButton = true
        vc.navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(customBackPressed)
        )
        // Swipe-back is managed via gestureRecognizerShouldBegin using `backAction`
        // (nav.interactivePopGestureRecognizer?.delegate = self set in init)
    }

    @objc private func customBackPressed() {
        guard
            let top = nav.topViewController as? OHHostingController,
            let any = top.anyRoute
        else {
            _ = nav.popViewController(animated: true)
            return
        }
        if let consume = RouteRegistry.shared.style(for: any)?.backAction, consume(any) {
            // custom handler consumed the back action; do not pop
            return
        }
        _ = nav.popViewController(animated: true)
    }

    // Block swipe-back if backAction says to consume it
    func gestureRecognizerShouldBegin(_ g: UIGestureRecognizer) -> Bool {
        guard
            let top = nav.topViewController as? OHHostingController,
            let any = top.anyRoute,
            let consume = RouteRegistry.shared.style(for: any)?.backAction
        else { return true }
        return !consume(any) // begin only if not consumed
    }

    // Re-apply per top VC after any push/pop/interactive pop
    func navigationController(_ navigationController: UINavigationController,
                              didShow viewController: UIViewController,
                              animated: Bool) {
        if let hc = viewController as? OHHostingController, let any = hc.anyRoute {
            applyBarAppearance(for: any)
        } else {
            restoreBaselineAppearance()
        }
    }
}
#endif
