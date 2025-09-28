//
//  File.swift
//  OHNavigationKit
//
//  Created by Ariesta Agung on 27/09/25.
//

import Foundation
import XCTest
@testable import OHNavigationKit
import SwiftUI


final class LegacyRouterTests: XCTestCase {
    enum R: Hashable, Codable { case home, detail(Int) }
    
    
    @MainActor func testReplaceStackUpdatesState() {
        if #available(iOS 16, *) { return } // legacy path only
        let router = Router<R>(root: .home) { _ in
            Text("V").eraseToAnyView()
        }
        router.replaceStack(with: [.detail(1), .detail(2)])
        XCTAssertEqual(router.currentStack, [.detail(1), .detail(2)])
    }
}
