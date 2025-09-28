//
//  File.swift
//  OHNavigationKit
//
//  Created by Ariesta Agung on 28/09/25.
//

import Foundation
import SwiftUI

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
