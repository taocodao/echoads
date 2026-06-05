// ContentView.swift
// Root navigation shell — Home channel grid → Player

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var env: AppEnvironment

    var body: some View {
        NavigationStack(path: Binding(
            get:  { env.router.path },
            set:  { env.router.path = $0 }
        )) {
            HomeView()
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .channel(let id):
                        PlayerView(channelId: id)
                    case .wallet:
                        WalletView()
                    }
                }
        }
        .tint(.indigo)
    }
}
