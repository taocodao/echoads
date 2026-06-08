// PlayerViewControllerRepresentable.swift — Arenza
// Wraps AVPlayerViewController for reliable video rendering on real devices.
//
// WHY: SwiftUI's VideoPlayer has known issues when presented inside
// fullScreenCover with complex ZStack overlays — the render surface
// may never attach on physical iPhones. AVPlayerViewController is
// Apple's recommended path for production video playback.

import SwiftUI
import AVKit

struct PlayerViewControllerRepresentable: UIViewControllerRepresentable {
    let player: AVPlayer

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let vc = AVPlayerViewController()
        vc.player = player
        vc.showsPlaybackControls = false   // We use custom overlays
        vc.allowsPictureInPicturePlayback = false
        vc.entersFullScreenWhenPlaybackBegins = false
        vc.exitsFullScreenWhenPlaybackEnds = false
        vc.videoGravity = .resizeAspectFill
        // Prevent the VC from showing its own dismiss gesture
        vc.canStartPictureInPictureAutomaticallyFromInline = false
        return vc
    }

    func updateUIViewController(_ vc: AVPlayerViewController, context: Context) {
        // Only update if the player instance actually changed
        if vc.player !== player {
            vc.player = player
        }
    }
}
