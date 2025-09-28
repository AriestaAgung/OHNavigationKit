//
//  File.swift
//  OHNavigationKit
//
//  Created by Ariesta Agung on 28/09/25.
//

import Foundation

public extension OHRouter where Route == AnyRoute {
  @MainActor
  func push<R: FeatureRoute>(_ route: R) {
    R.ensureRegistered()           // 🔑 make sure builder/encoders exist
    push(AnyRoute(route))
  }

  @MainActor
  func replaceStack<R: FeatureRoute>(with routes: [R]) {
    if let first = routes.first { type(of: first).ensureRegistered() }
    replaceStack(with: routes.map(AnyRoute.init))
  }

  @MainActor
  func setRoot<R: FeatureRoute>(_ route: R, children: [R] = []) {
    R.ensureRegistered()
    setRoot(AnyRoute(route), children: children.map(AnyRoute.init))
  }
}

@available(*, deprecated, message: "Use push(_: FeatureRoute) so routes auto-register.")
public extension OHRouter where Route == AnyRoute {
    func push<R: Hashable & Codable>(_ r: R) { push(AnyRoute(r)) }
    func replaceStack<R: Hashable & Codable>(with rs: [R]) { replaceStack(with: rs.map(AnyRoute.init)) }
}
