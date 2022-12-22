//
//  Client.swift
//  TCAStocks
//
//  Created by Alex Solonevich
//

import ComposableArchitecture
import Foundation
import XCTestDynamicOverlay

struct ApiClient {
    var baseUrl: @Sendable () throws -> URL
    var searchTickers: @Sendable (String, Bool) async throws -> [Ticker]
//    var searchTickersRawData: @Sendable (String, Bool) async throws -> (Data, URLResponse)
    var fetchQuotes: @Sendable (String) async throws -> [Quote]
//    var fetchQuotesRawData: @Sendable (String) async throws -> (Data, URLResponse)
}

extension ApiClient: TestDependencyKey {
    static let previewValue = Self(
        baseUrl: { URL(string: "https://query1.finance.yahoo.com")! },
        searchTickers: { _,_ in .mock },
//        searchTickersRawData: { _,_ in .mock },
        fetchQuotes: { _ in .mock }
//        fetchQuotesRawData: { _ in .mock }
    )
    
    static let testValue = Self(
        baseUrl: unimplemented("\(Self.self).baseUrl"),
        searchTickers: unimplemented("\(Self.self).searchTickers"),
//        searchTickersRawData: unimplemented("\(Self.self).searchTickersRawData"),
        fetchQuotes: unimplemented("\(Self.self).fetchQuotes")
//        fetchQuotesRawData: unimplemented("\(Self.self).fetchQuotesRawData")
    )
}

extension DependencyValues {
    var apiClient: ApiClient {
        get { self[ApiClient.self] }
        set { self[ApiClient.self] = newValue }
    }
}
