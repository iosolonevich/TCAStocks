//
//  Client.swift
//  TCAStocks
//
//  Created by Alex Solonevich
//

import Foundation

struct FileClient {
    var load: @Sendable (String) async throws -> Data
    var save: @Sendable (String, Data) async throws -> Void
    
//    var saved: [Ticker]?
    
    func load<A: Decodable>(_ type: A.Type, from filename: String) async throws -> A {
        try await JSONDecoder().decode(A.self, from: self.load(filename))
    }
    
    func save<A: Encodable>(_ data: A, to filename: String) async throws {
        try await self.save(filename, JSONEncoder().encode(data))
    }
}
