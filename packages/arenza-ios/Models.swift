// Models.swift
// All shared data models for the Arenza app.

import Foundation

// ── Channel ───────────────────────────────────────────────────────────────────
struct Channel: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let sport: String?
    let emoji: String?
    let tagline: String?
    let moqUrl: String?
}

// ── Program (EPG entry) ───────────────────────────────────────────────────────
struct Program: Identifiable, Codable {
    let id: String
    let title: String
    let startTime: Date
    let endTime: Date
    let description: String?
}

// ── SGAI Overlay ──────────────────────────────────────────────────────────────
struct SGAIOverlay: Identifiable {
    let id: String
    let productName: String
    let priceFormatted: String
    let emoji: String
    let impressionId: String
}

// ── Ad Break ──────────────────────────────────────────────────────────────────
struct AdBreak {
    let impressionId: String
    let duration: Double
    let winningCPM: Double
    let creativeURL: URL?
}

// ── Node Earnings ─────────────────────────────────────────────────────────────
struct NodeEarnings: Codable {
    let pendingCMXS: Double
    let claimedCMXS: Double
    let uptimeHours: Int
    let impressionsVerified: Int
}
