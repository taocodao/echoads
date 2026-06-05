// HomeViewModel.swift — Arenza Prototype

import Foundation
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var channels: [Channel] = []
    @Published var featuredChannel: Channel?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let env: AppEnvironment

    init(env: AppEnvironment) {
        self.env = env
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        // For prototype: use hardcoded demo channels
        // Production: GET /channels from CMXS content service
        channels = Channel.demoChannels
        featuredChannel = channels.first(where: { $0.isLive })
    }
}
