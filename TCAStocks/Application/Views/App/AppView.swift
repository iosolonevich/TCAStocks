//
//  AppView.swift
//  TCAStocks
//
//  Created by Alex Solonevich
//

import ComposableArchitecture
import SwiftUI

struct AppReducer: ReducerProtocol {
    struct State: Equatable {
        var appDelegateState: AppDelegateReducer.State
        var mainState: Main.State
        
        init(
            appDelegateState: AppDelegateReducer.State = AppDelegateReducer.State(),
            mainState: Main.State = Main.State(tickers: [])
        ) {
            self.appDelegateState = appDelegateState
            self.mainState = mainState
        }
    }
    
    //init with default values
    
    enum Action: Equatable {
        case appDelegate(AppDelegateReducer.Action)
        case main(Main.Action)
        case savedTickersLoaded(TaskResult<[Ticker]>)
    }
    
    @Dependency(\.fileClient) var fileClient
    
    init() {}
    
    @ReducerBuilder<State, Action> // how is CombineReducers {...} different?
    var body: some ReducerProtocol<State, Action> {
        self.core
            .onChange(of: \.mainState.tickers) { tickers, _, action in
                if case .savedTickersLoaded(.success) = action { return .none }
                return .fireAndForget {
                    try await self.fileClient.saveTickers(tickers: tickers)
                }
            }
            .onChange(of: \.mainState.searchState?.tickers) { tickers, _, _ in
                guard let tickers else { return .none }
                return
                    .merge(
                        .fireAndForget {
                            try await self.fileClient.saveTickers(tickers: tickers)
                        },
                        .run { send in
                            await send(
                                .savedTickersLoaded(
                                    TaskResult { try await self.fileClient.loadSavedTickers() }
                                )
                            )
                        }
                    )
            }
    }
    
    @ReducerBuilder<State, Action>
    var core: some ReducerProtocol<State, Action> {
        Scope(state: \.appDelegateState, action: /Action.appDelegate) {
            AppDelegateReducer()
        }
        Scope(state: \.mainState, action: /Action.main) {
            Main()
        }
        Reduce { state, action in
            switch action {
            
            case .appDelegate(.didFinishLaunching):
                return .run { send in
                    await send(
                        .savedTickersLoaded(
                            TaskResult { try await self.fileClient.loadSavedTickers() }
                        )
                    )
                }
            
            case .savedTickersLoaded(.failure):
                return .none
                
            case let .savedTickersLoaded(.success(tickers)):
                state.mainState.tickers = tickers
                return .none
                
            case .appDelegate:
                return .none
            
            case .main:
                return .none
            }
        }
    }
}

struct AppView: View {
    let store: StoreOf<AppReducer>
    @ObservedObject var viewStore: ViewStore<AppReducer.State, AppReducer.Action>
    
    public init(store: StoreOf<AppReducer>) {
        self.store = store
        self.viewStore = ViewStore(self.store)
    }
    
    var body: some View {
        NavigationStack {
            MainView(store: self.store.scope(state: \.mainState, action: AppReducer.Action.main))
        }
    }
}

struct AppView_Previews: PreviewProvider {
    static var previews: some View {
        AppView(
            store: Store(
                initialState: AppReducer.State(),
                reducer: AppReducer()
            )
        )
    }
}
