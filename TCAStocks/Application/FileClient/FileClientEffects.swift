//
//  FileClientEffects.swift
//  TCAStocks
//
//  Created by Alex Solonevich
//

import Foundation

extension FileClient {
    func loadSavedTickers() async throws -> [Ticker] {
        try await self.load([Ticker].self, from: savedTickersFileName)
    }
    
    func saveTickers(tickers: [Ticker]) async throws {
        try await self.save(tickers, to: savedTickersFileName)
    }
}

let savedTickersFileName = "saved-tickers"
