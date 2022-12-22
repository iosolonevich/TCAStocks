//
//  TestKey.swift
//  TCAStocks
//
//  Created by Alex Solonevich
//

import Dependencies
import Foundation

extension DependencyValues {
    var fileClient: FileClient {
        get { self[FileClient.self] }
        set { self[FileClient.self] = newValue }
    }
}

//extension FileClient: TestDependencyKey { ... }
