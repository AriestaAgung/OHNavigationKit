//
//  File.swift
//  OHNavigationKit
//
//  Created by Ariesta Agung on 28/09/25.
//

import Foundation
import SwiftUI

public final class RouteRegistry {
    public static let shared = RouteRegistry()
    private init() {}
    
    // Codable adapters (unchanged)
    public typealias _Enc = (AnyHashable, Encoder) throws -> Void
    public typealias _Dec = (Decoder) throws -> AnyHashable
    private var encoders: [String: _Enc] = [:]
    private var decoders: [String: _Dec] = [:]
    
    // Two distinct builder stores
    // Use typealiases to avoid parser confusion with attributes in collection types.
    typealias MainBuilder   = @MainActor (AnyHashable) -> AnyView     // can call @MainActor APIs
    typealias NonMainBuilder =            (AnyHashable) -> AnyView     // must NOT call @MainActor APIs
    
    private var mainBuilders:    [String: MainBuilder]    = [:]
    private var nonMainBuilders: [String: NonMainBuilder] = [:]
    
    // One-time registration bookkeeping (thread-safe)
    private var registeredTypeIDs = Set<ObjectIdentifier>()
    private let lock = NSLock()
    
    /// Ensure a feature’s registerRoutes() runs exactly once per concrete route type.
    @MainActor
    public func ensureRegistered<R: Hashable & Codable>(
        _ type: R.Type,
        _ register: @MainActor () -> Void
    ) {
        let key = ObjectIdentifier(type)
        if registeredTypeIDs.insert(key).inserted {
            register()
        }
    }
    
    // MARK: Register APIs
    
    /// Register a builder that **runs on the main actor** (safe to create @MainActor view models, etc).
    @MainActor
    public func registerMain<R: Hashable & Codable>(
        _ type: R.Type,
        builder: @escaping @MainActor (R) -> AnyView
    ) {
        let id = String(reflecting: R.self)
        
        mainBuilders[id] = { any in
            #if DEBUG
            guard let typed = any as? R else {
                assertionFailure("RouteRegistry.registerMain: type mismatch for \(id)")
                return AnyView(EmptyView())
            }
            return builder(typed)
            #else
            return builder(any as! R)
            #endif
        }
        
        encoders[id] = { any, enc in try (any as! R).encode(to: enc) }
        decoders[id] = { dec in AnyHashable(try R(from: dec)) }
    }
    
    /// Register a builder that **is NOT main-actor isolated**.
    /// Only use when the closure doesn’t touch @MainActor APIs (no UI/view-model inits marked @MainActor).
    public func registerNonMain<R: Hashable & Codable>(
        _ type: R.Type,
        builder: @escaping (R) -> AnyView
    ) {
        let id = String(reflecting: R.self)
        
        nonMainBuilders[id] = { any in
            #if DEBUG
            guard let typed = any as? R else {
                assertionFailure("RouteRegistry.registerNonMain: type mismatch for \(id)")
                return AnyView(EmptyView())
            }
            return builder(typed)
            #else
            return builder(any as! R)
            #endif
        }
        
        encoders[id] = { any, enc in try (any as! R).encode(to: enc) }
        decoders[id] = { dec in AnyHashable(try R(from: dec)) }
    }
    
    // MARK: Lookup
    
    /// Build the view for a route. Called from the router on the main actor.
    @MainActor
    public func view(for route: AnyRoute) -> AnyView? {
        if let main = mainBuilders[route.typeID] {
            return main(route.box)
        }
        if let nonMain = nonMainBuilders[route.typeID] {
            return nonMain(route.box)
        }
        return nil
    }
    
    public func encoder(for typeID: String) -> _Enc? { encoders[typeID] }
    public func decoder(for typeID: String) -> _Dec? { decoders[typeID] }
}

public let AnyRouteBuilder: OHRouteViewBuilder<AnyRoute> = { any in
    #if DEBUG
    if RouteRegistry.shared.view(for: any) == nil {
        assertionFailure("OHNavigationKit: Unregistered route: \(any.typeID). " +
                         "Did you push AnyRoute directly or forget to register?")
        return AnyView(Text("Missing view for \(any.typeID)"))
    } else {
        print("ASDASDAS")
        dump(RouteRegistry.shared.view(for: any))
    }
    #endif
    return RouteRegistry.shared.view(for: any) ?? AnyView(EmptyView())
}

