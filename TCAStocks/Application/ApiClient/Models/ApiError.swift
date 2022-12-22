//
//  ApiError.swift
//  TCAStocks
//
//  Created by Alex Solonevich
//

import Foundation

public struct ErrorResponse: Decodable {
    public let code: String
    public let description: String
    
    public init(code: String, description: String){
        self.code = code
        self.description = description
    }
}

public enum APIServiceError: Error {
    case invalidURL
    case invalidResponseType
    case httpStatusCodeFailed(statusCode: Int, error: ErrorResponse?)
    
    public var errorCode: Int {
        switch self {
        case .invalidURL: return 1
        case .invalidResponseType: return 2
        case .httpStatusCodeFailed: return 3
        }
    }
    
    public var errorUserInfo: [String : Any] {
        let text: String
        switch self {
        case .invalidURL:
            text = "Invalid URL"
        case .invalidResponseType:
            text = "Invalid Response Type"
        case let .httpStatusCodeFailed(statusCode, error):
            if let error = error {
                text = "Error: Status Code\(error.code), message: \(error.description)"
            } else {
                text = "Error: Status Code \(statusCode)"
            }
        }
        return [localizedDescription: text]
    }
}
