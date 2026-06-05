// Channel.swift — Arenza Prototype
// CMXS sports channel data model

import Foundation

struct Channel: Identifiable, Codable {
    let id: String
    let name: String
    let sport: String
    let thumbnailURL: URL?
    let isLive: Bool
    let currentProgram: String
    let viewerCount: Int

    static let demoChannels: [Channel] = [
        Channel(
            id: "cmxs-livgolf-r2",
            name: "LIV Golf",
            sport: "Golf",
            thumbnailURL: URL(string: "https://picsum.photos/seed/livgolf/400/225"),
            isLive: true,
            currentProgram: "LIV Golf Round 2 — Jeddah",
            viewerCount: 84_320
        ),
        Channel(
            id: "cmxs-usl-championship",
            name: "USL Championship",
            sport: "Soccer",
            thumbnailURL: URL(string: "https://picsum.photos/seed/soccer/400/225"),
            isLive: true,
            currentProgram: "Tampa Bay Rowdies vs Phoenix Rising",
            viewerCount: 41_750
        ),
        Channel(
            id: "cmxs-nba-g-league",
            name: "NBA G League",
            sport: "Basketball",
            thumbnailURL: URL(string: "https://picsum.photos/seed/basketball/400/225"),
            isLive: true,
            currentProgram: "South Bay Lakers vs Rio Grande Valley",
            viewerCount: 29_180
        ),
        Channel(
            id: "cmxs-fight-night",
            name: "Fight Night CMXS",
            sport: "MMA",
            thumbnailURL: URL(string: "https://picsum.photos/seed/mma/400/225"),
            isLive: false,
            currentProgram: "Next Event: Saturday 8PM ET",
            viewerCount: 0
        ),
        Channel(
            id: "cmxs-athletics-classics",
            name: "Athletics Classics",
            sport: "Athletics",
            thumbnailURL: URL(string: "https://picsum.photos/seed/athletics/400/225"),
            isLive: true,
            currentProgram: "2024 World Championships — Replay",
            viewerCount: 12_440
        ),
        Channel(
            id: "cmxs-motorsport",
            name: "CMXS Motorsport",
            sport: "Racing",
            thumbnailURL: URL(string: "https://picsum.photos/seed/racing/400/225"),
            isLive: false,
            currentProgram: "Formula E — Monaco ePrix Highlights",
            viewerCount: 0
        )
    ]
}
