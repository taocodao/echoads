// PlayerHostViewController.swift — Arenza
// UIViewController that owns AVPlayerViewController + SwiftUI overlays as siblings.
//
// WHY THIS PATTERN:
// AVPlayerViewController must be a UIKit child VC with a clean parentage to the
// UIWindow. SwiftUI's fullScreenCover wraps content in UIHostingController — any
// ZStack or Group around AVPlayerViewController inserts extra CALayer nodes into
// the compositor chain, breaking AVPlayerLayer attachment on real devices.
//
// Solution: This UIViewController is the fullScreenCover root. It contains:
//   1. AVPlayerViewController as a child VC (owns the full frame)
//   2. PlayerOverlayView (SwiftUI) inside a SIBLING UIHostingController
//      whose clear UIView sits on top — no ZStack wrapping the player.

import UIKit
import AVKit
import SwiftUI

final class PlayerHostViewController: UIViewController {

    // MARK: - Dependencies

    let vm: PlayerViewModel
    private let demo: DemoOrchestrator

    // MARK: - Child VCs

    private var playerVC: AVPlayerViewController!
    private var overlayHostingVC: UIHostingController<PlayerOverlayView>!

    // MARK: - Init

    init(vm: PlayerViewModel, demo: DemoOrchestrator) {
        self.vm = vm
        self.demo = demo
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }

    required init?(coder: NSCoder) { fatalError("Use init(vm:demo:)") }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        setupPlayerViewController()
        setupOverlayViewController()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Call play() here — after the VC is fully in the window hierarchy.
        // This guarantees AVPlayerLayer has attached before playback begins.
        vm.player?.play()
        print("[PlayerHostVC] viewDidAppear — play() called, player attached")
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        vm.stop()
        demo.stop()
    }

    override var prefersStatusBarHidden: Bool { true }
    override var prefersHomeIndicatorAutoHidden: Bool { true }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .allButUpsideDown }

    // MARK: - Setup

    private func setupPlayerViewController() {
        playerVC = AVPlayerViewController()
        playerVC.player = vm.player
        playerVC.showsPlaybackControls = false
        playerVC.videoGravity = .resizeAspectFill
        playerVC.allowsPictureInPicturePlayback = false

        // Proper UIKit child VC containment
        addChild(playerVC)
        view.addSubview(playerVC.view)
        playerVC.view.frame = view.bounds
        playerVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        playerVC.view.backgroundColor = .black
        playerVC.didMove(toParent: self)
    }

    private func setupOverlayViewController() {
        let overlayView = PlayerOverlayView(vm: vm, demo: demo) {
            // Dismiss callback
            self.dismiss(animated: true)
        }

        overlayHostingVC = UIHostingController(rootView: overlayView)
        overlayHostingVC.view.backgroundColor = .clear

        // Sibling UIView on top of player — no ZStack wrapping
        addChild(overlayHostingVC)
        view.addSubview(overlayHostingVC.view)
        overlayHostingVC.view.frame = view.bounds
        overlayHostingVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        overlayHostingVC.didMove(toParent: self)
    }

    // MARK: - Player Update (called when vm.player changes after init)

    func updatePlayer(_ player: AVPlayer) {
        playerVC?.player = player
    }
}
