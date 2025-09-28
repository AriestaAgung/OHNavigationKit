//
//  File.swift
//  OHNavigationKit
//
//  Created by Ariesta Agung on 28/09/25.
//

import Foundation

// AnyRoute + registry (from earlier sketches)
public struct AnyRoute: Hashable, Codable {
    let box: AnyHashable
    let typeID: String
    
    public init<R: Hashable & Codable>(_ value: R) {
        self.box = AnyHashable(value)
        self.typeID = String(reflecting: R.self)
    }
    
    enum CodingKeys: String, CodingKey { case type, payload }
    
    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(typeID, forKey: .type)
        guard let enc = RouteRegistry.shared.encoder(for: typeID) else {
            throw EncodingError.invalidValue(self, .init(codingPath: encoder.codingPath, debugDescription: "No encoder for \(typeID)"))
        }
        try enc(box, c.superEncoder(forKey: .payload))
    }
    
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let t = try c.decode(String.self, forKey: .type)
        guard let dec = RouteRegistry.shared.decoder(for: t) else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "No decoder for \(t)"))
        }
        self.box = try dec(c.superDecoder(forKey: .payload))
        self.typeID = t
    }
}
