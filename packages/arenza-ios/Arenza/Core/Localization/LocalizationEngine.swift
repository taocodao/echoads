// LocalizationEngine.swift — Arenza (Phase 5: Geo-Targeting)
// Translates GPS coordinate → DMA code → local sponsor ranking.
// Provides the "Near Me" tab with geo-sorted offers and detects stadium proximity.
//
// Privacy: uses CLLocationManager with "When In Use" permission only.
// Graceful degradation: if permission denied, falls back to national offers only.

import Foundation
import CoreLocation
import Combine

// MARK: - DMA Region (simplified hardcoded table for demo)
// In production: replace with a bundled SQLite or server-side lookup.

struct DMARegion {
    let code: String            // e.g. "501"
    let name: String            // e.g. "New York"
    let latitude: Double
    let longitude: Double
    let radiusKm: Double        // DMA coverage radius
}

// MARK: - Stadium

struct Stadium {
    let name: String
    let teamName: String
    let latitude: Double
    let longitude: Double
    let radiusMeters: Double    // geofence radius (typically 100m)
}

// MARK: - Localization Engine

@MainActor
final class LocalizationEngine: NSObject, ObservableObject {
    static let shared = LocalizationEngine()

    @Published var currentDMACode: String?
    @Published var currentDMAName: String?
    @Published var isAtStadium: Bool = false
    @Published var nearbyStadium: Stadium?
    @Published var authStatus: CLAuthorizationStatus = .notDetermined
    @Published var userLocation: CLLocation?

    private let manager = CLLocationManager()
    private var geofenceRegions: [CLCircularRegion] = []

    private override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer  // coarse — just need DMA
        manager.distanceFilter = 5000  // only update every 5km
        setupStadiumGeofences()
    }

    // MARK: - Permission + Location Start

    func requestLocationIfNeeded() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        default:
            break  // graceful no-op — marketplace falls back to national offers
        }
    }

    // MARK: - Rank offers by proximity

    /// Returns offers sorted: local first (if within radius), then national.
    func rankOffers(_ offers: [SponsorOffer]) -> [SponsorOffer] {
        guard let loc = userLocation else { return offers }

        return offers.sorted { a, b in
            let distA = a.distanceFrom(loc) ?? Double.infinity
            let distB = b.distanceFrom(loc) ?? Double.infinity
            // Local offers within radius come first, then by distance
            if distA == Double.infinity && distB == Double.infinity { return false }
            return distA < distB
        }
    }

    /// Filters offers to those local to the user's DMA code.
    func localOffers(from offers: [SponsorOffer]) -> [SponsorOffer] {
        guard let dma = currentDMACode else { return offers.filter { !$0.isLocalOnly } }
        return offers.filter { offer in
            !offer.isLocalOnly || offer.dmaCode == dma || offer.dmaCode == nil
        }
    }

    // MARK: - DMA lookup (simplified coordinate → DMA)

    private func resolveDMA(from location: CLLocation) {
        // Simplified: pick nearest DMA from hardcoded table
        let dma = DMADatabase.nearest(to: location)
        currentDMACode = dma?.code
        currentDMAName = dma?.name
        if let d = dma {
            print("[Geo] DMA resolved: \(d.code) \(d.name)")
        }
    }

    // MARK: - Stadium geofences

    private func setupStadiumGeofences() {
        for stadium in Stadium.demoStadiums {
            let center = CLLocationCoordinate2D(latitude: stadium.latitude, longitude: stadium.longitude)
            let region = CLCircularRegion(center: center, radius: stadium.radiusMeters, identifier: stadium.name)
            region.notifyOnEntry = true
            region.notifyOnExit = true
            geofenceRegions.append(region)
            // Note: CLLocationManager.startMonitoring requires Always permission on iOS
            // For demo, we use manual proximity check instead
        }
    }

    private func checkStadiumProximity(from location: CLLocation) {
        for stadium in Stadium.demoStadiums {
            let stadiumLoc = CLLocation(latitude: stadium.latitude, longitude: stadium.longitude)
            let distance = location.distance(from: stadiumLoc)
            if distance <= stadium.radiusMeters {
                isAtStadium = true
                nearbyStadium = stadium
                print("[Geo] Stadium Mode activated: \(stadium.name)")
                return
            }
        }
        isAtStadium = false
        nearbyStadium = nil
    }
}

// MARK: - CLLocationManagerDelegate

extension LocalizationEngine: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            self.userLocation = location
            self.resolveDMA(from: location)
            self.checkStadiumProximity(from: location)
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.authStatus = manager.authorizationStatus
            if manager.authorizationStatus == .authorizedWhenInUse ||
               manager.authorizationStatus == .authorizedAlways {
                manager.requestLocation()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("[Geo] Location error: \(error.localizedDescription)")
    }
}

// MARK: - DMA Database (hardcoded top 20 US DMAs for demo)

enum DMADatabase {
    static let regions: [DMARegion] = [
        DMARegion(code: "501", name: "New York",         latitude: 40.7128, longitude: -74.0060,  radiusKm: 100),
        DMARegion(code: "803", name: "Los Angeles",      latitude: 34.0522, longitude: -118.2437, radiusKm: 120),
        DMARegion(code: "602", name: "Chicago",          latitude: 41.8781, longitude: -87.6298,  radiusKm: 80),
        DMARegion(code: "504", name: "Philadelphia",     latitude: 39.9526, longitude: -75.1652,  radiusKm: 70),
        DMARegion(code: "618", name: "Dallas-Ft. Worth", latitude: 32.7767, longitude: -96.7970,  radiusKm: 90),
        DMARegion(code: "506", name: "Boston",           latitude: 42.3601, longitude: -71.0589,  radiusKm: 70),
        DMARegion(code: "511", name: "Washington DC",    latitude: 38.9072, longitude: -77.0369,  radiusKm: 75),
        DMARegion(code: "524", name: "Atlanta",          latitude: 33.7490, longitude: -84.3880,  radiusKm: 85),
        DMARegion(code: "528", name: "Miami",            latitude: 25.7617, longitude: -80.1918,  radiusKm: 70),
        DMARegion(code: "539", name: "Tampa",            latitude: 27.9506, longitude: -82.4572,  radiusKm: 65),
        DMARegion(code: "543", name: "Minneapolis",      latitude: 44.9778, longitude: -93.2650,  radiusKm: 75),
        DMARegion(code: "555", name: "Phoenix",          latitude: 33.4484, longitude: -112.0740, radiusKm: 85),
        DMARegion(code: "560", name: "Seattle-Tacoma",   latitude: 47.6062, longitude: -122.3321, radiusKm: 80),
        DMARegion(code: "571", name: "Denver",           latitude: 39.7392, longitude: -104.9903, radiusKm: 80),
        DMARegion(code: "577", name: "Houston",          latitude: 29.7604, longitude: -95.3698,  radiusKm: 90),
        DMARegion(code: "598", name: "San Francisco",    latitude: 37.7749, longitude: -122.4194, radiusKm: 80),
        DMARegion(code: "609", name: "Detroit",          latitude: 42.3314, longitude: -83.0458,  radiusKm: 70),
        DMARegion(code: "616", name: "Cleveland",        latitude: 41.4993, longitude: -81.6944,  radiusKm: 65),
        DMARegion(code: "619", name: "Nashville",        latitude: 36.1627, longitude: -86.7816,  radiusKm: 70),
        DMARegion(code: "673", name: "Las Vegas",        latitude: 36.1699, longitude: -115.1398, radiusKm: 60),
    ]

    static func nearest(to location: CLLocation) -> DMARegion? {
        regions.min { a, b in
            let locA = CLLocation(latitude: a.latitude, longitude: a.longitude)
            let locB = CLLocation(latitude: b.latitude, longitude: b.longitude)
            return location.distance(from: locA) < location.distance(from: locB)
        }
    }
}

// MARK: - Demo Stadiums

extension Stadium {
    static let demoStadiums: [Stadium] = [
        Stadium(name: "MetLife Stadium",      teamName: "NY Giants/Jets",  latitude: 40.8135, longitude: -74.0745, radiusMeters: 200),
        Stadium(name: "SoFi Stadium",         teamName: "LA Rams/Chargers",latitude: 33.9535, longitude: -118.3392,radiusMeters: 200),
        Stadium(name: "AT&T Stadium",         teamName: "Dallas Cowboys",  latitude: 32.7473, longitude: -97.0945, radiusMeters: 200),
        Stadium(name: "Allegiant Stadium",    teamName: "Las Vegas Raiders",latitude: 36.0909, longitude: -115.1833,radiusMeters: 200),
        Stadium(name: "Arrowhead Stadium",    teamName: "Kansas City Chiefs",latitude: 39.0489, longitude: -94.4839,radiusMeters: 200),
    ]
}
