//
//  File.swift
//  OHNavigationKit
//
//  Created by Ariesta Agung on 27/09/25.
//

import Foundation
import XCTest
import SwiftUI
@testable import OHNavigationKit


@available(iOS 16, *)
final class StackRouterTests: XCTestCase {
    enum R: Hashable, Codable { case home, detail(Int) }
    
    
    @MainActor func testPushPop() {
        let router = StackRouter<R>(root: .home) { route in
            switch route {
            case .home: return Text("Home").eraseToAnyView()
            case .detail(let i): return Text("Detail\\(i)").eraseToAnyView()
            }
        }
        
        
        XCTAssertEqual(router.currentStack.count, 0)
        router.push(.detail(1))
        XCTAssertEqual(router.currentStack, [.detail(1)])
        router.pop()
        XCTAssertEqual(router.currentStack.count, 0)
    }
}
