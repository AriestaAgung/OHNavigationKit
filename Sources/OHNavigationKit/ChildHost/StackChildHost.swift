//
//  File.swift
//  OHNavigationKit
//
//  Created by Ariesta Agung on 28/09/25.
//

import Foundation
import SwiftUI

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
