//
//  SearchView.swift
//  TCAStocks
//
//  Created by Alex Solonevich
//

import ComposableArchitecture
import SwiftUI

struct Searching: ReducerProtocol {
    struct State: Equatable {
        var tickers: [Ticker]
        var searchQuery: String
        var searchResults: [Ticker]?
        var searchResultsQuotesDict: [String:Quote]?
    }
    
    enum Action: Equatable {
        case searchQueryChangeDebounced
        case searchResponse(TaskResult<[Ticker]>)
        case fetchQuotesForResults
        case quotesResponse(TaskResult<[Quote]>)
        case toggleTicker(Ticker)
    }
    
//    @Dependency(\.fileClient) var fileClient
    @Dependency(\.apiClient) var apiClient
    
    private enum SearchTickerID {}
    private enum FetchQuotesID {}
    
    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
            
        case .searchQueryChangeDebounced:
            guard !state.searchQuery.isEmpty else {
                return .none
            }
            
            return
                .task { [query = state.searchQuery] in
                    await .searchResponse(TaskResult { try await
                        self.apiClient.searchTickers(query, true)
                    })
                }
                .debounce(id: SearchTickerID.self, for: 0.25, scheduler: DispatchQueue.main)
                .cancellable(id: SearchTickerID.self)

        case .searchResponse(.failure):
            state.searchResults = []
            return .none
            
        case let .searchResponse(.success(response)):
            state.searchResults = response
            return .none
            
        case .fetchQuotesForResults:
            guard let searchResults = state.searchResults, !searchResults.isEmpty else {
                return .none
            }
            let symbols = searchResults.map { $0.symbol }.joined(separator: ",")
            
            return
                .task { //TODO: include 'symbols' in the capture list?
                    await .quotesResponse(TaskResult { try await
                        self.apiClient.fetchQuotes(symbols)
                    })
                }
                .cancellable(id: FetchQuotesID.self)
            
        case .quotesResponse(.failure):
            //TODO: display smth like "-:-" ?
            state.searchResultsQuotesDict = [:]
            return .none

        case let .quotesResponse(.success(quotes)):
            var dict = [String:Quote]()
            quotes.forEach { dict[$0.symbol] = $0 }
            state.searchResultsQuotesDict = dict
            return .none
            
        case let .toggleTicker(ticker):
            if state.tickers.first { $0.symbol == ticker.symbol } != nil {
                guard let index = state.tickers.firstIndex(where: { $0.symbol == ticker.symbol }) else { return .none}
                
                state.tickers.remove(at: index)
            } else {
                state.tickers.append(ticker)
            }
            return .none
        }
    }
}


struct SearchableListView: View {
    let store: StoreOf<Searching>
    @ObservedObject var viewStore: ViewStore<Searching.State, Searching.Action>
    
    public init(store: StoreOf<Searching>) {
        self.store = store
        self.viewStore = ViewStore(self.store)
    }
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            List {
                ForEach(viewStore.searchResults ?? [], id: \.self) { ticker in
                    TickerListRowView(
                        symbol: ticker.symbol,
                        name: ticker.shortname,
                        price: getQuotesForTicker(ticker: ticker),
                        rowType: .search(
                            isSaved: isAddedToMyTickers(ticker: ticker),
                            onButtonTapped: {
                                Task { @MainActor in //TODO: MainActor isnt neccessary
                                    viewStore.send(.toggleTicker(ticker))
                                }
                            }
                        )
                    )
                }
            }
            .listStyle(.plain)
            .task(id: viewStore.searchQuery) {
                do {
                    await viewStore.send(.searchQueryChangeDebounced)
                }
            }
            .task(id: viewStore.searchResults) {
                do {
                    await viewStore.send(.fetchQuotesForResults)
                }
            }
        }
    }
    
    func isAddedToMyTickers(ticker: Ticker) -> Bool {
        viewStore.tickers.first { $0.symbol == ticker.symbol } != nil
    }
    
    func getQuotesForTicker(ticker: Ticker) -> PriceChange? {
        guard let quote = viewStore.searchResultsQuotesDict?[ticker.symbol],
              let price = quote.regularPriceText,
              let change = quote.regularDiffText else { return nil }
        return (price, change)
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchableListView(
//            store: Store(
//                initialState: Main.State(),
//                reducer: Main()
//            )
            store: Store(
                initialState: Searching.State(
                    tickers: [
                        Ticker(symbol: "AAPL"),
                        Ticker(symbol: "AMZN"),
                        Ticker(symbol: "GOOGL")
                    ],
                    searchQuery: "GOOGL"
                ),
                reducer: Searching()
            )
        )
    }
}
