//
//  MainView.swift
//  TCAStocks
//
//  Created by Alex Solonevich
//

import ComposableArchitecture
import SwiftUI

struct Main: ReducerProtocol {
    struct State: Equatable {
        var tickers: [Ticker]
        var tickersQuotesDict: [String:Quote]?
        var titleText = "Stocks"
        var subtitleText: String {
            subtitleDateFormatter.string(from: Date())
        }
        var emptyTickersText = "Search and add a symbol to see a stock quotes"
        var attributionText = "Powered by Yahoo! finance API"
        
        var searchState: Searching.State?
        var searchQuery: String = ""
        var isSearching: Bool {
            return !searchQuery.isEmpty
        }
        
        private let subtitleDateFormatter: DateFormatter = {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "d MMM"
            return dateFormatter
        }()

    }

    enum Action: Equatable {
        case fetchQuotesForTickers
        case quotesResponse(TaskResult<[Quote]>)
        
        case searchQueryChanged(String)
        case searching(Searching.Action)
        
        case tickerSwipeRemove(IndexSet)
        
        case openYahooFinance
    }
    
    @Dependency(\.apiClient) var apiClient
    @Dependency(\.fileClient) var fileClient
    
    private enum SearchTickerID {}
    private enum FetchQuotesID {}

    var body: some ReducerProtocol<State, Action> {
        Reduce { state, action in
            switch action {

            case .fetchQuotesForTickers:
                guard !state.tickers.isEmpty else {
                    return .none
                }
                let symbols = state.tickers.map { $0.symbol }.joined(separator: ",")
                
                return
                    .task { //TODO: include 'symbols' in the capture list?
                        await .quotesResponse(TaskResult { try await
                            self.apiClient.fetchQuotes(symbols)
                        })
                    }
                    .cancellable(id: FetchQuotesID.self)
                
            case .quotesResponse(.failure):
                //TODO: display smth like "-:-" ?
                state.tickersQuotesDict = [:]
                return .none

            case let .quotesResponse(.success(quotes)):
                var dict = [String:Quote]()
                quotes.forEach { dict[$0.symbol] = $0 }
                state.tickersQuotesDict = dict
                return .none
                
            case let .searchQueryChanged(query):
                state.searchQuery = query
                if query.isEmpty {
                    state.searchState = nil
                    return .cancel(id: SearchTickerID.self)
                } else {
                    state.searchState = Searching.State(tickers: state.tickers, searchQuery: query)
                    return .none
                }
                
            case let .tickerSwipeRemove(indexSet):
                state.tickers.remove(atOffsets: indexSet)
                return .none
                
            case .openYahooFinance:
                let url = URL(string: "https://finance.yahoo.com")!
//                guard UIApplication.shared.canOpenURL(url) else { return }
                UIApplication.shared.open(url)
                return .none
  
            case .searching:
                return .none
            }
        }
        .ifLet(\.searchState, action: /Action.searching) {
            Searching()
        }
        
    }
}

struct MainView: View {
    let store: StoreOf<Main>
    @ObservedObject var viewStore: ViewStore<Main.State, Main.Action>
    
    public init(store: StoreOf<Main>) {
        self.store = store
        self.viewStore = ViewStore(self.store)
    }
    
    var body: some View {
        tickerListView
            .listStyle(.plain)
            .overlay(searching)
            .toolbar {
                titleToolbar
                attributionToolbar
            }
            .searchable(
                text: viewStore.binding(
                    get: \.searchQuery,
                    send: Main.Action.searchQueryChanged
                )
            )
            .task(id: viewStore.tickers) {
                do {
                    await viewStore.send(.fetchQuotesForTickers)
                }
            }
    }
    
    private var tickerListView: some View {
        List {
            ForEach(viewStore.tickers) { ticker in
                TickerListRowView(
                    symbol: ticker.symbol,
                    name: ticker.shortname,
                    price: getQuotesForTicker(ticker: ticker),
                    rowType: .main
                )
                .contentShape(Rectangle())
            }
            .onDelete { viewStore.send(.tickerSwipeRemove($0)) }
        }
    }
    
    @ViewBuilder
    private var overlayView: some View {
        if viewStore.tickers.isEmpty {
            EmptyStateView(text: viewStore.emptyTickersText)
        }
    }
    
    var searching: some View {
        IfLetStore(
            store.scope(state: \.searchState, action: Main.Action.searching),
            then: SearchableListView.init(store:)
        )
    }
    
    private var titleToolbar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            VStack(alignment: .leading, spacing: -4) {
                Text(viewStore.titleText)
                Text(viewStore.subtitleText).foregroundColor(Color(uiColor: .secondaryLabel))
            }
            .font(.title2.weight(.heavy))
            .padding(.bottom)
        }
    }
    
    private var attributionToolbar: some ToolbarContent {
        ToolbarItem(placement: .bottomBar) {
            HStack {
                Button {
                    viewStore.send(.openYahooFinance)
                } label: {
                    Text(viewStore.attributionText)
                        .font(.caption.weight(.heavy))
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                }
                .buttonStyle(.plain)
                
                Spacer()
            }
        }
    }
    
    func getQuotesForTicker(ticker: Ticker) -> PriceChange? {
        guard let quote = viewStore.tickersQuotesDict?[ticker.symbol],
              let price = quote.regularPriceText,
              let change = quote.regularDiffText else { return nil }
        return (price, change)
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView(store: Store(
            initialState: Main.State(tickers: [ Ticker(symbol: "AAPL"), Ticker(symbol: "TSLA") ]),
            reducer: Main()
        ))
    }
}
