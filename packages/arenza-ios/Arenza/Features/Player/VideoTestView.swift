// VideoTestView.swift — Arenza (Diagnostic)
// Bare-bones video playback test to isolate black screen bug.
// Shows THREE different players at once with status labels.
// If ALL three are black → AVPlayer or network problem.
// If some play → specific stream URL problem.
// Access: Triple-tap the ARENZA header in HomeView.

import SwiftUI
import AVKit
import AVFoundation

struct VideoTestView: View {
    @Environment(\.dismiss) private var dismiss

    // Three different known-good streams to test simultaneously
    private let streams: [(name: String, url: String)] = [
        ("Apple Basic (4:3 TS)", "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8"),
        ("Mux Big Buck Bunny", "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8"),
        ("Apple Advanced (fMP4)", "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Text("VIDEO PLAYBACK DIAGNOSTIC")
                        .font(.system(size: 14, weight: .black))
                        .foregroundColor(.yellow)
                        .tracking(2)
                        .padding(.top, 8)

                    Text("If you see video below, playback works.\nIf black, there is a fundamental AVPlayer issue.")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    ForEach(streams, id: \.name) { stream in
                        StreamTestCard(name: stream.name, urlString: stream.url)
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 16)
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Stream Test")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundColor(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Individual Stream Test Card

struct StreamTestCard: View {
    let name: String
    let urlString: String

    @StateObject private var tester = StreamTester()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Stream label
            HStack {
                Text(name)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                statusBadge
            }

            // Player
            ZStack {
                Color(white: 0.1)
                
                if let player = tester.player {
                    VideoPlayer(player: player)
                        .frame(height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    ProgressView()
                        .tint(.white)
                        .frame(height: 180)
                }
            }
            .frame(height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            // Debug info
            Text(tester.debugLog)
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.white.opacity(0.4))
                .lineLimit(4)

            Text(urlString)
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(.white.opacity(0.25))
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .padding(12)
        .background(Color(white: 0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(tester.statusColor.opacity(0.3), lineWidth: 1)
        )
        .onAppear {
            tester.test(urlString: urlString)
        }
        .onDisappear {
            tester.stop()
        }
    }

    private var statusBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(tester.statusColor)
                .frame(width: 6, height: 6)
            Text(tester.statusText)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(tester.statusColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(tester.statusColor.opacity(0.1))
        .clipShape(Capsule())
    }
}

// MARK: - Stream Tester (per-stream ViewModel)

@MainActor
final class StreamTester: ObservableObject {
    @Published var player: AVPlayer?
    @Published var statusText: String = "LOADING"
    @Published var statusColor: Color = .orange
    @Published var debugLog: String = ""

    private var statusObserver: NSKeyValueObservation?
    private var errorObserver: NSKeyValueObservation?
    private var timeObserver: Any?
    private var startTime: Date?

    func test(urlString: String) {
        guard let url = URL(string: urlString) else {
            statusText = "BAD URL"
            statusColor = .red
            debugLog = "Invalid URL string"
            return
        }

        startTime = Date()
        log("Creating AVPlayerItem...")

        let item = AVPlayerItem(url: url)
        let avPlayer = AVPlayer(playerItem: item)
        avPlayer.automaticallyWaitsToMinimizeStalling = true

        // Observe item status
        statusObserver = item.observe(\.status, options: [.new, .initial]) { [weak self] item, _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                switch item.status {
                case .readyToPlay:
                    let elapsed = self.elapsedMs()
                    self.statusText = "READY"
                    self.statusColor = .green
                    self.log("readyToPlay in \(elapsed)ms")
                    self.log("Duration: \(item.duration.seconds)s")
                    self.log("Tracks: \(item.tracks.count)")
                    // Check if video track exists
                    let videoTracks = item.tracks.filter { $0.assetTrack?.mediaType == .video }
                    self.log("Video tracks: \(videoTracks.count)")
                    if videoTracks.isEmpty {
                        self.log("⚠️ NO VIDEO TRACKS FOUND")
                        self.statusText = "NO VIDEO"
                        self.statusColor = .red
                    }
                case .failed:
                    self.statusText = "FAILED"
                    self.statusColor = .red
                    self.log("FAILED: \(item.error?.localizedDescription ?? "unknown")")
                case .unknown:
                    self.statusText = "LOADING"
                    self.statusColor = .orange
                    self.log("Status: unknown (buffering...)")
                @unknown default:
                    break
                }
            }
        }

        // Observe error
        errorObserver = item.observe(\.error, options: [.new]) { [weak self] item, _ in
            Task { @MainActor [weak self] in
                if let error = item.error {
                    self?.log("ERROR: \(error.localizedDescription)")
                    self?.statusText = "ERROR"
                    self?.statusColor = .red
                }
            }
        }

        // Observe actual playback progress
        timeObserver = avPlayer.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 2, preferredTimescale: 1),
            queue: .main
        ) { [weak self] time in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if time.seconds > 0 {
                    self.statusText = "PLAYING"
                    self.statusColor = .green
                    self.log("Playing at \(String(format: "%.1f", time.seconds))s")
                }
            }
        }

        self.player = avPlayer
        avPlayer.play()
        log("play() called")
    }

    func stop() {
        if let timeObserver, let player {
            player.removeTimeObserver(timeObserver)
        }
        player?.pause()
        player = nil
        statusObserver = nil
        errorObserver = nil
    }

    private func log(_ msg: String) {
        let ts = elapsedMs()
        debugLog += "[\(ts)ms] \(msg)\n"
        print("[StreamTest] \(msg)")
    }

    private func elapsedMs() -> Int {
        guard let start = startTime else { return 0 }
        return Int(Date().timeIntervalSince(start) * 1000)
    }
}
