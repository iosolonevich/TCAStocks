//
//  TickerListRowView.swift
//  TCAStocks
//
//  Created by Alex Solonevich
//

import ComposableArchitecture
import SwiftUI

typealias PriceChange = (price: String, change: String)

enum TickerListRowType {
    case main
    case search(isSaved: Bool, onButtonTapped: () -> ())
}

struct TickerListRowView: View {
    let symbol: String
    let name: String?
    let price: PriceChange?
    let rowType: TickerListRowType
    
    var body: some View {
        HStack(alignment: .center) {
            if case let .search(isSaved, onButtonTapped) = rowType {
                Button {
                    onButtonTapped()
                } label: {
                    image(isSaved: isSaved)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(symbol)
                    .font(.headline.bold())
                if let name {
                    Text(name)
                        .font(.subheadline)
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                }
            }

            Spacer()
            
            if let (price, change) = price {
                VStack(alignment: .trailing, spacing: 4) {
                    Text(price)
                    priceChangeView(rowType: rowType, text: change)
                }
                .font(.headline.bold())
            }
        }
    }
    
    @ViewBuilder
    func image(isSaved: Bool) -> some View {
        if isSaved {
            Image(systemName: "checkmark.circle.fill")
                .symbolRenderingMode(.palette)
                .foregroundStyle(.white, Color.accentColor)
                .imageScale(.large)
        } else {
            Image(systemName: "plus.circle.fill")
                .symbolRenderingMode(.palette)
                .foregroundStyle(Color.accentColor, Color.secondary.opacity(0.3))
                .imageScale(.large)
        }
    }
    
    @ViewBuilder
    func priceChangeView(rowType: TickerListRowType, text: String) -> some View {
        if case .main = rowType {
            ZStack(alignment: .trailing) {
                RoundedRectangle(cornerRadius: 4)
                    .foregroundColor((text.hasPrefix("-") ? .red : .green))
                    .frame(height: 24)
                
                Text(text)
                    .foregroundColor(.white)
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
            }
            .fixedSize()
        } else {
            Text(text)
                .foregroundColor(text.hasPrefix("-") ? .red : .green)
        }
    }
}

struct TickerListRowView_Previews: PreviewProvider {
    static var previews: some View {
        TickerListRowView(
            symbol: "AMZN",
            name: "Amazon",
            price: ("110", "-2.5"),
            rowType: .search(isSaved: false, onButtonTapped: {})
        )
    }
}
