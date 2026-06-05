// HomeViewModel.swift

import Foundation
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var channels: [Channel] = []
    @Published var featured: Channel?

    // ── Demo fallback channels (no API needed for demo) ──────────────────────
    private let demoChannels: [Channel] = [
        Channel(id: "livgolf", name: "LIV Golf Live", sport: "Golf",
                emoji: "⛳", tagline: "Every shot, real-time", moqUrl: Constants.moqStreamURL),
        Channel(id: "ufc-live", name: "UFC 300 Live", sport: "MMA",
                emoji: "🥊", tagline: "Sub-300ms delivery", moqUrl: Constants.moqStreamURL),
        Channel(id: "nfl-sunday", name: "NFL Sunday", sport: "Football",
                emoji: "🏈", tagline: "Verified $47.50 CPM", moqUrl: Constants.moqStreamURL),
        Channel(id: "nba-finals", name: "NBA Finals", sport: "Basketball",
                emoji: "🏀", tagline: "FAST channel, no cable", moqUrl: Constants.moqStreamURL),
        Channel(id: "soccer-ml", name: "MLS Live", sport: "Soccer",
                emoji: "⚽", tagline: "On-chain proof every 35s", moqUrl: Constants.moqStreamURL),
        Channel(id: "tennis-wimb", name: "Wimbledon", sport: "Tennis",
                emoji: "🎾", tagline: "0% Roku tax", moqUrl: Constants.moqStreamURL),
    ]

    func load() async {
        // Try real API first, fall back to demo data
        channels = demoChannels
        featured = demoChannels.first
    }
}

// ── Constants ────────────────────────────────────────────────────────────────
enum Constants {
    // MoQ test stream via Caton's public relay
    static let moqStreamURL   = "https://us-west.moq-demo.liveviewing.com:4444/anon"
    static let moqDemoPageURL = "https://moq-demo.caton.cloud/moq-demo/?server=\(moqStreamURL)"

    // Backend (staging fallback for demo)
    static let apiBase = "https://api.cmxs.io/v1"

    // Base Sepolia testnet – populated after contract deploy
    static let cmxsTokenAddress    = "0x0000000000000000000000000000000000000000" // TBD
    static let oracleAddress       = "0x0000000000000000000000000000000000000000" // TBD
    static let baseSepolia         = 84532
}
