import SwiftUI
import Combine

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

