// PlayerView.swift — Arenza
// Thin SwiftUI shell — delegates entirely to PlayerViewControllerRepresentable.
//
// WHY SO SIMPLE:
// AVPlayerViewController requires a clean UIKit parentage to the UIWindow.
// Any SwiftUI ZStack/Group wrapping it breaks CALayer attachment on real devices.
// The actual player + overlays live in PlayerHostViewController (UIKit).
// See PlayerHostViewController.swift for the full implementation.

import SwiftUI
import AVKit

struct PlayerView: View {
    let channel: Channel
    @EnvironmentObject var env: AppEnvironment
    @StateObject private var vm: PlayerViewModel

    init(channel: Channel) {
        self.channel = channel
        self._vm = StateObject(wrappedValue: PlayerViewModel(channel: channel, env: .shared))
    }

    var body: some View {
        // PlayerHostViewController is the sole root of this fullScreenCover.
        // No ZStack. No Group. No wrapper. Just the UIKit VC bridge.
        PlayerViewControllerRepresentable(vm: vm, demo: DemoOrchestrator.shared)
            .ignoresSafeArea()
            .task {
                // Player was pre-created in vm.init(). This starts ancillary services.
                await vm.startPlayback()
                // Also start demo orchestrator
                DemoOrchestrator.shared.start(for: vm)
            }
    }
}
