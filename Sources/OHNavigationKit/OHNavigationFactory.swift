//
//  File.swift
//  OHNavigationKit
//
//  Created by Ariesta Agung on 27/09/25.
//

import SwiftUI

public typealias Route = Hashable & Codable

@MainActor
public enum OHNavigationFactory {

    // NEW: Preferred overload (no unused `root` param).
    public static func makeRouter<T: Route>(
        builder: @escaping OHRouteViewBuilder<T>
    ) -> Any {
        if #available(iOS 16, *) {
            return StackRouter<T>(builder: builder)
        } else {
            return OHRouter<T>(builder: builder)
        }
    }

    // Back-compat: keep the old signature so existing call-sites don’t break.
    @available(*, deprecated, message: "Pass only `builder:`; `root` is not needed.")
    public static func makeRouter<T: Route>(
        root: T,
        builder: @escaping OHRouteViewBuilder<T>
    ) -> Any {
        makeRouter(builder: builder)
    }
}
