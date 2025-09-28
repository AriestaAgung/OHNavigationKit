import SwiftUI
import Combine

/// iOS 13+ backport of `@StateObject`.
/// Persists the reference in `@State` (stable identity) and forwards changes via `@ObservedObject`.
@propertyWrapper
public struct StateObjectCompat<ObjectType>: DynamicProperty where ObjectType: ObservableObject {
    @State private var storage: ObjectType
    @ObservedObject private var observed: ObjectType

    public init(wrappedValue make: @autoclosure @escaping () -> ObjectType) {
        let instance = make()
        _storage  = State(initialValue: instance)
        _observed = ObservedObject(wrappedValue: instance)
    }

    public mutating func update() { _observed = ObservedObject(wrappedValue: storage) }

    public var wrappedValue: ObjectType { storage }
    public var projectedValue: ObservedObject<ObjectType>.Wrapper { $observed }
}

// iOS 13 host (works on all OS versions — internal)
struct LegacyChildHost<Route: Hashable & Codable, Root: View>: View {
    @StateObjectCompat private var router: OHRouter<Route>
    private let root: () -> Root

    init(builder: @escaping OHRouteViewBuilder<Route>,
         @ViewBuilder root: @escaping () -> Root) {
        _router = StateObjectCompat(wrappedValue: OHRouter<Route>(builder: builder))
        self.root = root
    }

    var body: some View {
        router.root { root() }            // router picks UIKit engine (13–15) / NavigationStack (16+)
            .environmentObject(router)
    }
}

@available(iOS 14, *)
struct StackChildHost<Route: Hashable & Codable, Root: View>: View {
    @StateObject private var router: OHRouter<Route>
    private let root: () -> Root

    init(builder: @escaping OHRouteViewBuilder<Route>,
         @ViewBuilder root: @escaping () -> Root) {
        _router = StateObject(wrappedValue: OHRouter<Route>(builder: builder))
        self.root = root
    }

    var body: some View {
        router.root { root() }
            .environmentObject(router)
    }
}

/// Public single entry that picks the right host internally.
public struct ChildHost<Route: Hashable & Codable, Root: View>: View {
    private let builder: OHRouteViewBuilder<Route>
    private let root: () -> Root

    public init(builder: @escaping OHRouteViewBuilder<Route>,
                @ViewBuilder root: @escaping () -> Root) {
        self.builder = builder
        self.root = root
    }

    public var body: some View {
        Group {
            if #available(iOS 14, *) {
                StackChildHost(builder: builder, root: root)
            } else {
                LegacyChildHost(builder: builder, root: root)
            }
        }
    }
}

