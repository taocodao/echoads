// AppEnvironment.swift
// Centralised dependency container injected via @EnvironmentObject.

import SwiftUI
import Combine

final class AppEnvironment: ObservableObject {
    let api      = CMXSAPIClient()
    let router   = AppRouter()
    let wallet   = WalletService()

    // Shared player state so deep-links can resume playback
    @Published var currentChannel: Channel?
}

// ─── Lightweight router ──────────────────────────────────────────────────────
final class AppRouter: ObservableObject {
    @Published var path = NavigationPath()

    // arenza://channel/livgolf-r2
    // arenza://wallet
    func handleDeepLink(_ url: URL) {
        guard url.scheme == "arenza", let host = url.host else { return }
        switch host {
        case "channel":
            let channelId = url.lastPathComponent
            path.append(Route.channel(channelId))
        case "wallet":
            path.append(Route.wallet)
        default:
            break
        }
    }
}

enum Route: Hashable {
    case channel(String)
    case wallet
}
