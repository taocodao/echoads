// PlayerViewControllerRepresentable.swift — Arenza
// Bridges PlayerHostViewController into SwiftUI's fullScreenCover.
// PlayerHostViewController is the ROOT — no wrapping ZStack.

import SwiftUI
import UIKit

struct PlayerViewControllerRepresentable: UIViewControllerRepresentable {
    @ObservedObject var vm: PlayerViewModel
    let demo: DemoOrchestrator

    func makeUIViewController(context: Context) -> PlayerHostViewController {
        let vc = PlayerHostViewController(vm: vm, demo: demo)
        return vc
    }

    func updateUIViewController(_ vc: PlayerHostViewController, context: Context) {
        // Update player if it changes
        if let player = vm.player {
            vc.updatePlayer(player)
        }
    }
}
