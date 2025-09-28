//
//  File.swift
//  OHNavigationKit
//
//  Created by Ariesta Agung on 28/09/25.
//

import Foundation
import SwiftUI

/// iOS 13+ backport of `@StateObject`.
/// Persists the reference in `@State` (stable identity) and forwards changes via `@ObservedObject`.
@propertyWrapper
public struct StateObjectCompat<ObjectType>: DynamicProperty where ObjectType: ObservableObject {
    @State private var storage: ObjectType
    @ObservedObject private var observed: ObjectType

    public init(wrappedValue make: @autoclosure @escaping () -> ObjectType) {
        let instance = make()
        _storage  = State(initialValue: instance)
        _observed = ObservedObject(wrappedValue: instance)
    }

    public mutating func update() { _observed = ObservedObject(wrappedValue: storage) }

    public var wrappedValue: ObjectType { storage }
    public var projectedValue: ObservedObject<ObjectType>.Wrapper { $observed }
}
