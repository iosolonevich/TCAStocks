//
//  Quote+Extensions.swift
//  TCAStocks
//
//  Created by Alex Solonevich
//

import Foundation

extension Quote {
    var regularPriceText: String? {
        Utils.format(value: regularMarketPrice)
    }

    var regularDiffText: String? {
        guard let text = Utils.format(value: regularMarketChange) else { return nil }
        return text.hasPrefix("-") ? text : "+\(text)"
    }
}
