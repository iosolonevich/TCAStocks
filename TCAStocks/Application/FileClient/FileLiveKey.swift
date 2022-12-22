//
//  LiveKey.swift
//  TCAStocks
//
//  Created by Alex Solonevich
//

import Dependencies
import Foundation

extension FileClient: DependencyKey {
    static let liveValue = {
        let documentDirectory = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first!
        
        return Self(
            load: {
                try Data(
                    contentsOf: documentDirectory.appendingPathComponent($0).appendingPathExtension("json")
                )
            },
            save: {
                try $1.write(to: documentDirectory.appendingPathComponent($0)
                    .appendingPathExtension("json"))
            }
        )
    }()
}
