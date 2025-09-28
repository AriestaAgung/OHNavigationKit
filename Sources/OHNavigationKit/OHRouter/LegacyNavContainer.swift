//
//  File.swift
//  OHNavigationKit
//
//  Created by Ariesta Agung on 28/09/25.
//

import Foundation
import SwiftUI

#if canImport(UIKit)
@MainActor struct LegacyNavContainer: UIViewControllerRepresentable {
    let provider: () -> UINavigationController
    init(_ provider: @escaping () -> UINavigationController) { self.provider = provider }

    func makeUIViewController(context: Context) -> UIViewController { provider() }
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
#endif
