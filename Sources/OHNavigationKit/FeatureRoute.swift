//
//  FeatureRoute.swift
//  OHNavigationKit
//
//  Created by Ariesta Agung on 28/09/25.
//

public protocol FeatureRoute: Hashable & Codable {
    static func registerRoutes()
}

public extension FeatureRoute {
    /// One-time registration for this concrete route type.
    
    @MainActor static func ensureRegistered() {
        RouteRegistry.shared.ensureRegistered(Self.self, self.registerRoutes)
    }
}
