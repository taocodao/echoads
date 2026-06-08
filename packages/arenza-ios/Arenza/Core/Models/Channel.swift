// Channel.swift — Arenza
// CMXS sports channel data model.
// streamURL: direct HLS source used by AVPlayer — always set for every demo channel.
// These URLs are chosen for maximum reliability on TestFlight / real devices.

import Foundation

struct Channel: Identifiable, Codable {
    let id: String
    let name: String
    let sport: String
    let thumbnailURL: URL?
    let isLive: Bool
    let currentProgram: String
    let viewerCount: Int
    /// Direct HLS URL for AVPlayer. Always non-nil for demo channels.
    let streamURL: URL?

    // ─── Reliable HLS Sources ───────────────────────────────────────────────
    // Chosen for zero geo-block and consistent uptime on iOS / TestFlight.
    // • appleAdvFmp4  — Apple's advanced multi-bitrate fMP4 sample (Apple CDN)
    // • appleBipbop   — Apple's legacy 16x9 multi-bitrate test stream
    // • muxBBB        — Mux-hosted Big Buck Bunny (fast global CDN)
    // For production: replace with Vercel-hosted sports HLS or SSAI manifest.
    private enum Streams {
        static let appleAdvFmp4 = URL(string:
            "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8")!
        static let appleBipbop  = URL(string:
            "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8")!
        static let appleBasic   = URL(string:
            "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8")!
        static let muxBBB       = URL(string:
            "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8")!
    }

    static let demoChannels: [Channel] = [
        Channel(
            id: "cmxs-nfl-live",
            name: "NFL Sunday",
            sport: "Football",
            thumbnailURL: URL(string: "https://picsum.photos/seed/football/400/225"),
            isLive: true,
            currentProgram: "Patriots vs Eagles — Q3 10:47",
            viewerCount: 284_320,
            streamURL: Streams.muxBBB             // 100% reliable TS stream
        ),
        Channel(
            id: "cmxs-nba-live",
            name: "NBA Tonight",
            sport: "Basketball",
            thumbnailURL: URL(string: "https://picsum.photos/seed/basketball/400/225"),
            isLive: true,
            currentProgram: "Lakers vs Celtics — Halftime",
            viewerCount: 142_880,
            streamURL: Streams.appleBipbop
        ),
        Channel(
            id: "cmxs-mlb-live",
            name: "MLB Network",
            sport: "Baseball",
            thumbnailURL: URL(string: "https://picsum.photos/seed/baseball/400/225"),
            isLive: true,
            currentProgram: "Yankees vs Red Sox — Bottom 7th",
            viewerCount: 98_540,
            streamURL: Streams.muxBBB
        ),
        Channel(
            id: "cmxs-ufc-live",
            name: "UFC Fight Night",
            sport: "MMA",
            thumbnailURL: URL(string: "https://picsum.photos/seed/mma/400/225"),
            isLive: true,
            currentProgram: "Main Card — Bout 3 of 5",
            viewerCount: 201_000,
            streamURL: Streams.appleAdvFmp4
        ),
        Channel(
            id: "cmxs-pga-live",
            name: "PGA Tour",
            sport: "Golf",
            thumbnailURL: URL(string: "https://picsum.photos/seed/golf/400/225"),
            isLive: true,
            currentProgram: "US Open — Round 3 Back Nine",
            viewerCount: 64_210,
            streamURL: Streams.appleBipbop
        ),
        Channel(
            id: "cmxs-premier-league",
            name: "Premier League",
            sport: "Soccer",
            thumbnailURL: URL(string: "https://picsum.photos/seed/soccer/400/225"),
            isLive: false,
            currentProgram: "Next: Man City vs Arsenal — Sat 7:30 AM ET",
            viewerCount: 0,
            streamURL: Streams.appleBasic
        ),
    ]
}
