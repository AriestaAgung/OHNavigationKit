//
//  File.swift
//  OHNavigationKit
//
//  Created by Ariesta Agung on 28/09/25.
//

import Foundation
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

public final class RouteRegistry {
    public static let shared = RouteRegistry()
    private init() {}

    // MARK: - Codable adapters
    public typealias _Enc = (AnyHashable, Encoder) throws -> Void
    public typealias _Dec = (Decoder) throws -> AnyHashable
    private var encoders: [String: _Enc] = [:]
    private var decoders: [String: _Dec] = [:]

    // MARK: - View builders
    typealias MainBuilder    = @MainActor (AnyHashable) -> AnyView
    typealias NonMainBuilder =            (AnyHashable) -> AnyView
    private var mainBuilders:    [String: MainBuilder]    = [:]
    private var nonMainBuilders: [String: NonMainBuilder] = [:]

    // MARK: - Optional per-type nav styles
    private var styles: [String: OHNavStyle] = [:]

    // MARK: - One-time registration
    private var registeredTypeIDs = Set<ObjectIdentifier>()
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

    // MARK: - Register APIs

    @MainActor
    public func registerMain<R: Hashable & Codable>(
        _ type: R.Type,
        style: OHNavStyle? = nil,
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
        if let s = style { styles[id] = s }
        encoders[id] = { any, enc in try (any as! R).encode(to: enc) }
        decoders[id] = { dec in AnyHashable(try R(from: dec)) }
    }

    public func registerNonMain<R: Hashable & Codable>(
        _ type: R.Type,
        style: OHNavStyle? = nil,
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
        if let s = style { styles[id] = s }
        encoders[id] = { any, enc in try (any as! R).encode(to: enc) }
        decoders[id] = { dec in AnyHashable(try R(from: dec)) }
    }

    // MARK: - Lookup

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

    public func style(for route: AnyRoute) -> OHNavStyle? {
        styles[route.typeID]
    }

    @MainActor
    public func title(for route: AnyRoute) -> String? {
        styles[route.typeID]?.title(route)
    }

    public func encoder(for typeID: String) -> _Enc? { encoders[typeID] }
    public func decoder(for typeID: String) -> _Dec? { decoders[typeID] }
}

// MARK: - Per-route navigation style

public struct OHNavStyle {
    public var title: (AnyRoute) -> String?
    public var prefersLargeTitles: Bool
    #if canImport(UIKit)
    public var backgroundColor: UIColor?
    public var titleColor: UIColor?
    public var tintColor: UIColor?
    #endif
    public var backAction: ((AnyRoute) -> Bool)?

    public init(
        title: @escaping (AnyRoute) -> String? = { _ in nil },
        prefersLargeTitles: Bool = false,
        backgroundColor: UIColor? = nil,
        titleColor: UIColor? = nil,
        tintColor: UIColor? = nil,
        backAction: ((AnyRoute) -> Bool)? = nil
    ) {
        self.title = title
        self.prefersLargeTitles = prefersLargeTitles
        self.backgroundColor = backgroundColor
        self.titleColor = titleColor
        self.tintColor = tintColor
        self.backAction = backAction
    }
}

// MARK: - AnyRoute builder (applies title only in SwiftUI; colors handled by LegacyEngine)

private struct _OHNavTitleModifier: ViewModifier {
    let title: String?
    @ViewBuilder
    func body(content: Content) -> some View {
        if let t = title {
            if #available(iOS 14, *) {
                content.navigationTitle(t)
            } else {
                content
            }
        } else {
            content
        }
    }
}

public let AnyRouteBuilder: OHRouteViewBuilder<AnyRoute> = { any in
    #if DEBUG
    if RouteRegistry.shared.view(for: any) == nil {
        assertionFailure("OHNavigationKit: Unregistered route: \(any.typeID).")
        return AnyView(Text("Missing view for \(any.typeID)"))
    }
    #endif

    let base = RouteRegistry.shared.view(for: any) ?? AnyView(EmptyView())
    let titled = base.modifier(_OHNavTitleModifier(title: RouteRegistry.shared.title(for: any)))
    return AnyView(titled)
}
