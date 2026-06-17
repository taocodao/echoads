// AdVideoPlayerView.swift — Arenza
// AVPlayer wrapper for inline commercial break video playback.
// Mirrors web demo: ad video plays in the bottom zone with real progress tracking.
// Fires onEnded() when the video truly finishes (video.ended equivalent).

import SwiftUI
import AVFoundation
import Combine

// MARK: - Ad Video Player View Model

@MainActor
final class AdVideoPlayerViewModel: ObservableObject {
    @Published var progress: Double = 0.0   // 0.0 → 1.0
    @Published var isReady = false

    var player: AVPlayer?
    private var timeObserver: Any?
    private var endObserver: AnyCancellable?
    private var onEnded: (() -> Void)?

    func load(url: URL, onEnded: @escaping () -> Void) {
        self.onEnded = onEnded
        let item = AVPlayerItem(url: url)
        let p = AVPlayer(playerItem: item)
        p.isMuted = true   // Web demo: ad videos always play silently (v.muted=true; v.volume=0)
        p.volume = 0
        p.automaticallyWaitsToMinimizeStalling = true
        self.player = p

        // Progress tracking — updates every 0.25s
        let interval = CMTime(seconds: 0.25, preferredTimescale: 600)
        timeObserver = p.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self, weak p] time in
            guard let self, let p, let duration = p.currentItem?.duration,
                  duration.isValid, !duration.isIndefinite else { return }
            let d = CMTimeGetSeconds(duration)
            let c = CMTimeGetSeconds(time)
            if d > 0 { self.progress = min(1.0, c / d) }
        }

        // End detection
        endObserver = NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime, object: item)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.progress = 1.0
                self?.onEnded?()
            }

        // Start playing once buffered
        item.publisher(for: \.status).receive(on: DispatchQueue.main).sink { [weak self, weak p] status in
            if status == .readyToPlay {
                self?.isReady = true
                p?.play()
            }
        }.store(in: &cancellables)
    }

    func cleanup() {
        if let obs = timeObserver { player?.removeTimeObserver(obs) }
        timeObserver = nil
        endObserver = nil
        player?.pause()
        player = nil
        isReady = false
        progress = 0.0
    }

    private var cancellables = Set<AnyCancellable>()
}

// MARK: - Ad Video Player View

struct AdVideoPlayerView: View {
    @StateObject private var vm = AdVideoPlayerViewModel()
    let ad: AdCreative
    @Binding var progress: Double
    let onEnded: () -> Void

    var body: some View {
        ZStack {
            Color.black

            if vm.isReady, let player = vm.player {
                PlayerLayerView(player: player)
            } else {
                VStack(spacing: 12) {
                    Text(ad.emoji).font(.system(size: 48))
                    Text("Loading…")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.5))
                    ProgressView().tint(.white)
                }
            }
        }
        .onChange(of: vm.progress) { p in progress = p }
        .onAppear {
            if let url = ad.videoURL {
                vm.load(url: url, onEnded: onEnded)
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(ad.durationSec)) {
                    onEnded()
                }
            }
        }
        .onDisappear { vm.cleanup() }
    }
}
