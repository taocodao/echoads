// Channel.swift — Arenza
// CMXS sports channel data model
// streamURL: always-available HLS source — used directly by AVPlayer when the
// SSAI backend is unreachable (i.e. all device testing via TestFlight).

import Foundation

struct Channel: Identifiable, Codable {
    let id: String
    let name: String
    let sport: String
    let thumbnailURL: URL?
    let isLive: Bool
    let currentProgram: String
    let viewerCount: Int
    /// Direct HLS playback URL — set for every demo channel.
    /// AVPlayer plays this when the SSAI backend is offline.
    let streamURL: URL?

    // Public HLS test streams (no auth, no CORS, no geo-block):
    //  • Mux Big Buck Bunny — multi-bitrate VOD loop (always works)
    //  • Apple Bipbop       — Apple official multi-bitrate test
    //  • Caton MoQ bridge   — live CMAF-over-HLS from the MoQ relay (pilot)
    private enum Streams {
        static let bbb      = URL(string: "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8")!
        static let bipbop   = URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8")!
        static let sintel   = URL(string: "https://bitdash-a.akamaihd.net/content/sintel/hls/playlist.m3u8")!
        static let tears    = URL(string: "https://bitdash-a.akamaihd.net/content/MI201109210084_1/m3u8s/f08e80da-bf1d-4e3d-8899-f0f6155f6efa.m3u8")!
    }

    static let demoChannels: [Channel] = [
        Channel(
            id: "cmxs-livgolf-r2",
            name: "LIV Golf",
            sport: "Golf",
            thumbnailURL: URL(string: "https://picsum.photos/seed/livgolf/400/225"),
            isLive: true,
            currentProgram: "LIV Golf Round 2 — Jeddah",
            viewerCount: 84_320,
            streamURL: Streams.bbb
        ),
        Channel(
            id: "cmxs-usl-championship",
            name: "USL Championship",
            sport: "Soccer",
            thumbnailURL: URL(string: "https://picsum.photos/seed/soccer/400/225"),
            isLive: true,
            currentProgram: "Tampa Bay Rowdies vs Phoenix Rising",
            viewerCount: 41_750,
            streamURL: Streams.bipbop
        ),
        Channel(
            id: "cmxs-nba-g-league",
            name: "NBA G League",
            sport: "Basketball",
            thumbnailURL: URL(string: "https://picsum.photos/seed/basketball/400/225"),
            isLive: true,
            currentProgram: "South Bay Lakers vs Rio Grande Valley",
            viewerCount: 29_180,
            streamURL: Streams.sintel
        ),
        Channel(
            id: "cmxs-fight-night",
            name: "Fight Night CMXS",
            sport: "MMA",
            thumbnailURL: URL(string: "https://picsum.photos/seed/mma/400/225"),
            isLive: false,
            currentProgram: "Next Event: Saturday 8PM ET",
            viewerCount: 0,
            streamURL: Streams.tears
        ),
        Channel(
            id: "cmxs-athletics-classics",
            name: "Athletics Classics",
            sport: "Athletics",
            thumbnailURL: URL(string: "https://picsum.photos/seed/athletics/400/225"),
            isLive: true,
            currentProgram: "2024 World Championships — Replay",
            viewerCount: 12_440,
            streamURL: Streams.bbb
        ),
        Channel(
            id: "cmxs-motorsport",
            name: "CMXS Motorsport",
            sport: "Racing",
            thumbnailURL: URL(string: "https://picsum.photos/seed/racing/400/225"),
            isLive: false,
            currentProgram: "Formula E — Monaco ePrix Highlights",
            viewerCount: 0,
            streamURL: Streams.bipbop
        )
    ]
}

