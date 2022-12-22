//
//  TCAStocksApp.swift
//  TCAStocks
//
//  Created by Alex Solonevich
//

import ComposableArchitecture
import SwiftUI

final class AppDelegate: NSObject, UIApplicationDelegate {
    let store = Store(
        initialState: AppReducer.State(),
        reducer: AppReducer()
    )
    
    var viewStore: ViewStore<Void, AppReducer.Action> {
        ViewStore(self.store.stateless)
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        self.viewStore.send(.appDelegate(.didFinishLaunching))
        return true
    }
}

@main
struct TCAStocksApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    
    var body: some Scene {
        WindowGroup {
            AppView(store: self.appDelegate.store)
        }
    }
}
