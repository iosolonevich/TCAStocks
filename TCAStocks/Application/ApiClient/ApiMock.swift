//
//  Mock.swift
//  TCAStocks
//
//  Created by Alex Solonevich
//

import Foundation

extension Array where Element == Ticker {
    static let mock = Self([
        Ticker(symbol: "AAPL"),
        Ticker(symbol: "GOOGL"),
        Ticker(symbol: "TSLA")
    ])
}

extension Array where Element == Quote {
    static let mock = Self([
        Quote(symbol: "AAPL"),
        Quote(symbol: "GOOGL"),
        Quote(symbol: "TSLA")
    ])
}
