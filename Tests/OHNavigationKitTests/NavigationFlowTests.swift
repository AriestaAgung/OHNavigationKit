import XCTest
import SwiftUI
@testable import OHNavigationKit

@MainActor
final class NavigationFlowTests: XCTestCase {

    override func setUp() {
        super.setUp()
        TestViewFactory.reset()
    }

    func testEnsureRegisteredBuildsViewsAndStyles() {
        TestFeatureRoute.ensureRegistered()

        let detailRoute = AnyRoute(TestFeatureRoute.detail(id: 42))
        let homeRoute = AnyRoute(TestFeatureRoute.home)

        TestViewFactory.reset()

        let detailView = RouteRegistry.shared.view(for: detailRoute)
        XCTAssertNotNil(detailView)
        XCTAssertEqual(TestViewFactory.builtRoutes, [.detail(id: 42)])

        let homeView = RouteRegistry.shared.view(for: homeRoute)
        XCTAssertNotNil(homeView)
        XCTAssertEqual(TestViewFactory.builtRoutes, [.detail(id: 42), .home])

        XCTAssertEqual(RouteRegistry.shared.title(for: detailRoute), "Detail 42")
        XCTAssertEqual(RouteRegistry.shared.title(for: homeRoute), "Home")
    }

    func testOHRouterSupportsFullNavigationFlow() {
        let router = OHRouter<AnyRoute>(builder: AnyRouteBuilder)
        TestFeatureRoute.ensureRegistered()

        router.push(TestFeatureRoute.home)
        router.push(TestFeatureRoute.detail(id: 1))
        XCTAssertEqual(router.currentStack.compactMap(TestFeatureRoute.init(anyRoute:)), [.home, .detail(id: 1)])

        router.replaceStack(with: [TestFeatureRoute.detail(id: 2), .settings] as [TestFeatureRoute])
        XCTAssertEqual(router.currentStack.compactMap(TestFeatureRoute.init(anyRoute:)), [.detail(id: 2), .settings])

        router.pop()
        XCTAssertEqual(router.currentStack.compactMap(TestFeatureRoute.init(anyRoute:)), [.detail(id: 2)])

        router.popToRoot()
        XCTAssertTrue(router.currentStack.isEmpty)

        router.setRoot(TestFeatureRoute.home, children: [TestFeatureRoute.detail(id: 3)])
        XCTAssertEqual(router.currentStack.compactMap(TestFeatureRoute.init(anyRoute:)), [.detail(id: 3)])
    }

    @available(iOS 16, *)
    func testStackRouterMaintainsNavigationPath() {
        let router = StackRouter<TestFeatureRoute>(builder: { route in
            TestViewFactory.builtRoutes.append(route)
            return TestScreen(route: route).eraseToAnyView()
        })

        XCTAssertTrue(router.currentStack.isEmpty)
        router.push(.detail(id: 5))
        router.push(.settings)
        XCTAssertEqual(router.currentStack, [.detail(id: 5), .settings])

        router.pop()
        XCTAssertEqual(router.currentStack, [.detail(id: 5)])

        router.replaceStack(with: [.home, .settings])
        XCTAssertEqual(router.currentStack, [.home, .settings])

        router.popToRoot()
        XCTAssertTrue(router.currentStack.isEmpty)
    }

    func testOHRouterDeallocatesAfterFlow() {
        weak var weakRouter: OHRouter<AnyRoute>?

        autoreleasepool {
            let router = OHRouter<AnyRoute>(builder: AnyRouteBuilder)
            TestFeatureRoute.ensureRegistered()
            router.push(TestFeatureRoute.detail(id: 10))
            router.pop()
            weakRouter = router
        }

        runLoopDrain()
        XCTAssertNil(weakRouter)
    }

    @available(iOS 16, *)
    func testStackRouterDeallocatesAfterFlow() {
        weak var weakRouter: StackRouter<TestFeatureRoute>?

        autoreleasepool {
            let router = StackRouter<TestFeatureRoute> { route in
                TestViewFactory.builtRoutes.append(route)
                return TestScreen(route: route).eraseToAnyView()
            }
            router.push(.detail(id: 2))
            router.pop()
            weakRouter = router
        }

        runLoopDrain()
        XCTAssertNil(weakRouter)
    }

    // Drain the run loop to let deallocation happen.
    private func runLoopDrain(iterations: Int = 3) {
        for _ in 0..<iterations {
            RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.01))
        }
    }
}

private enum TestViewFactory {
    static var builtRoutes: [TestFeatureRoute] = []

    static func reset() {
        builtRoutes.removeAll(keepingCapacity: true)
    }
}

@MainActor
private enum TestFeatureRoute: FeatureRoute, Equatable {
    case home
    case detail(id: Int)
    case settings

    static func registerRoutes() {
        RouteRegistry.shared.registerMain(Self.self, style: OHNavStyle(title: { anyRoute in
            guard let route = TestFeatureRoute(anyRoute: anyRoute) else { return nil }
            return route.displayTitle
        })) { route in
            TestViewFactory.builtRoutes.append(route)
            return TestScreen(route: route).eraseToAnyView()
        }
    }

    init?(anyRoute: AnyRoute) {
        guard let typed = anyRoute.box as? TestFeatureRoute else { return nil }
        self = typed
    }

    var displayTitle: String {
        switch self {
        case .home: return "Home"
        case .detail(let id): return "Detail \(id)"
        case .settings: return "Settings"
        }
    }
}

private struct TestScreen: View {
    let route: TestFeatureRoute

    var body: some View {
        Text(route.displayTitle)
            .padding()
    }
}
