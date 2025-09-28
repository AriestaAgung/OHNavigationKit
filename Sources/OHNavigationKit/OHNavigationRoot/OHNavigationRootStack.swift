//
//  File.swift
//  OHNavigationKit
//
//  Created by Ariesta Agung on 28/09/25.
//

import Foundation
import SwiftUI

/// Convenience root view for iOS 16+ using NavigationStack.
@available(iOS 16, *)
public struct OHNavigationRootStack<Route: Hashable & Codable, RootContent: View>: View {
    @ObservedObject private var router: StackRouter<Route>
    private let rootContent: () -> RootContent
    
    public init(router: StackRouter<Route>, @ViewBuilder content: @escaping () -> RootContent) {
        self.router = router
        self.rootContent = content
    }
    
    public var body: some View {
        NavigationStack(path: $router.path) {
            rootContent()
                .navigationDestination(for: Route.self) { r in
                    router.destinationView(for: r)
                }
        }
    }
}
