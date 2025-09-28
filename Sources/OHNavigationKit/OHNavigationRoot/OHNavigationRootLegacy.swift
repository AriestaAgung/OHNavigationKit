//
//  File.swift
//  OHNavigationKit
//
//  Created by Ariesta Agung on 27/09/25.
//

import SwiftUI

/// iOS 13–15: mount UINavigationController that hosts your SwiftUI root.
@available(iOS, introduced: 13, obsoleted: 16)
public struct OHNavigationRootLegacy<Route: Hashable & Codable, RootContent: View>: View {
    @ObservedObject private var router: OHRouter<Route>
    private let rootContent: () -> RootContent
    
    public init(router: OHRouter<Route>, @ViewBuilder content: @escaping () -> RootContent) {
        self.router = router
        self.rootContent = content
    }
    
    public var body: some View {
        // Unified entry — OHRouter turns this into a UIHostingController inside a UINavigationController.
        router.root { rootContent() }
    }
}
