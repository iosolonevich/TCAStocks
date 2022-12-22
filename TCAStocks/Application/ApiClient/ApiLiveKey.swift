//
//  LiveKey.swift
//  TCAStocks
//
//  Created by Alex Solonevich
//

import ComposableArchitecture
import Foundation

extension ApiClient: DependencyKey {
    static let liveValue = Self.live()
    
    static func live(
        baseUrl defaultBaseUrl: URL = URL(string: "https://query1.finance.yahoo.com")!
    ) -> Self {
        return Self(
            baseUrl: {
                defaultBaseUrl
            },
            
            searchTickers: { query, isEquityTypeOnly in
                guard var urlComponents = URLComponents(string: "\(defaultBaseUrl)/v1/finance/search") else {
                    throw APIServiceError.invalidURL
                }
                
                urlComponents.queryItems = [
                    URLQueryItem(name: "lang", value: "en-US"),
                    URLQueryItem(name: "quotesCount", value: "20"),
                    URLQueryItem(name: "q", value: query)
                ]
                
                guard let url = urlComponents.url else {
                    throw APIServiceError.invalidURL
                }

                let (response, statusCode): (SearchTickersResponse, Int) = try await fetch(url: url)
                if let error = response.error {
                    throw APIServiceError.httpStatusCodeFailed(statusCode: statusCode, error: error)
                }

                let data = response.data ?? []
                if isEquityTypeOnly {
                    return data.filter { ($0.quoteType ?? "").localizedCaseInsensitiveCompare("equity") == .orderedSame }
                } else {
                    return data
                }
            },
            
            fetchQuotes: { symbols in
                guard var urlComponents = URLComponents(string: "\(defaultBaseUrl)/v7/finance/quote") else {
                    throw APIServiceError.invalidURL
                }
                
                urlComponents.queryItems = [URLQueryItem(name: "symbols", value: symbols)]
                guard let url = urlComponents.url else {
                    throw APIServiceError.invalidURL
                }

                let (response, statusCode): (QuoteResponse, Int) = try await fetch(url: url)
                
                if let error = response.error {
                    throw APIServiceError.httpStatusCodeFailed(statusCode: statusCode, error: error)
                }
                
                return response.data ?? []
            }
        )
    }
}

private func fetch<D: Decodable>(url: URL) async throws -> (D, Int) {
    let (data, response) = try await URLSession.shared.data(from: url)
    let statusCode = try validateHTTPResponse(response: response)
    return (try jsonDecoder.decode(D.self, from: data), statusCode)
}

private func validateHTTPResponse(response: URLResponse) throws -> Int {
    guard let httpResponse = response as? HTTPURLResponse else {
        throw APIServiceError.invalidResponseType
    }
    
    guard 200...299 ~= httpResponse.statusCode ||
            400...499 ~= httpResponse.statusCode
    else {
        throw APIServiceError.httpStatusCodeFailed(statusCode: httpResponse.statusCode, error: nil)
    }
    
    return httpResponse.statusCode
}

private let jsonDecoder: JSONDecoder = {
  let decoder = JSONDecoder()
  let formatter = DateFormatter()
  formatter.calendar = Calendar(identifier: .iso8601)
  formatter.dateFormat = "yyyy-MM-dd"
  formatter.timeZone = TimeZone(secondsFromGMT: 0)
  formatter.locale = Locale(identifier: "en_US_POSIX")
  decoder.dateDecodingStrategy = .formatted(formatter)
  return decoder
}()
