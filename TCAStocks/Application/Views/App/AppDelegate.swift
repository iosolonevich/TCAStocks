//
//  AppDelegate.swift
//  TCAStocks
//
//  Created by Alex Solonevich
//

import ComposableArchitecture
import Foundation

struct AppDelegateReducer: ReducerProtocol {
    struct State: Equatable {
        
    }
    
    enum Action: Equatable {
        case didFinishLaunching
    }
    
//    @Dependency(\.fileClient) var fileClient
    
    init() {}
    
    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
            
        case .didFinishLaunching:
            
            return .none
        }
    }
}
