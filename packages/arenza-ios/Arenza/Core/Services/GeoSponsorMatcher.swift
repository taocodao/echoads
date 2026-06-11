// GeoSponsorMatcher.swift — Arenza
// CoreLocation-based sponsor prioritization.
// Sorts SponsorBusiness.all by proximity to the user's current location,
// so nearby sponsors appear first in the spin wheel and sponsor info card.
//
// Resolves GAP 6 from the optimization plan.
// Uses "When In Use" permission (low friction, upgradeable to "Always" later).

import Foundation
import CoreLocation
import SwiftUI
import Combine

// MARK: - Geo Sponsor Matcher

@MainActor
final class GeoSponsorMatcher: NSObject, ObservableObject {

    static let shared = GeoSponsorMatcher()

    // MARK: - Published

    @Published private(set) var sortedSponsors: [SponsorBusiness] = SponsorBusiness.all
    @Published private(set) var userLocation: CLLocation?
    @Published private(set) var locationAuthorized: Bool = false
    @Published private(set) var nearestSponsor: SponsorBusiness? = nil
    @Published private(set) var nearestDistanceMiles: Double? = nil

    // MARK: - Config

    /// Default radius (miles) within which a sponsor is considered "nearby"
    private let nearbyRadiusMiles: Double = 5.0

    // MARK: - Private

    private let manager = CLLocationManager()

    private override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.distanceFilter = 500 // update every 500m
    }

    // MARK: - Public API

    func requestLocationIfNeeded() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationAuthorized = true
            manager.startUpdatingLocation()
        default:
            locationAuthorized = false
            sortedSponsors = SponsorBusiness.all // fallback: natural order
        }
    }

    func distanceMiles(to business: SponsorBusiness) -> Double? {
        guard let userLoc = userLocation,
              let bizCoord = business.coordinate else { return nil }
        let bizLoc = CLLocation(latitude: bizCoord.latitude, longitude: bizCoord.longitude)
        return userLoc.distance(from: bizLoc) / 1609.344 // meters to miles
    }

    func isNearby(_ business: SponsorBusiness) -> Bool {
        guard let dist = distanceMiles(to: business) else { return false }
        return dist <= nearbyRadiusMiles
    }

    // MARK: - Sort

    private func updateSortedSponsors() {
        guard let userLoc = userLocation else {
            sortedSponsors = SponsorBusiness.all
            return
        }

        let sorted = SponsorBusiness.all.sorted { a, b in
            let distA = a.coordinate.map { CLLocation(latitude: $0.latitude, longitude: $0.longitude).distance(from: userLoc) } ?? .infinity
            let distB = b.coordinate.map { CLLocation(latitude: $0.latitude, longitude: $0.longitude).distance(from: userLoc) } ?? .infinity
            return distA < distB
        }

        sortedSponsors = sorted
        nearestSponsor = sorted.first
        nearestDistanceMiles = sorted.first.flatMap { distanceMiles(to: $0) }
    }
}

// MARK: - CLLocationManagerDelegate

extension GeoSponsorMatcher: CLLocationManagerDelegate {

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                self.locationAuthorized = true
                manager.startUpdatingLocation()
            default:
                self.locationAuthorized = false
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        Task { @MainActor in
            self.userLocation = loc
            self.updateSortedSponsors()
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("[Geo] Location error: \(error.localizedDescription)")
    }
}

// MARK: - SponsorBusiness Extension (coordinates for demo)

extension SponsorBusiness {
    /// Demo coordinates — production would come from API/backend
    var coordinate: CLLocationCoordinate2D? {
        switch id {
        case "sakura-bites":   return CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194) // SF
        case "copper-grill":   return CLLocationCoordinate2D(latitude: 37.7751, longitude: -122.4181) // SF (0.1mi away)
        case "tap-room":       return CLLocationCoordinate2D(latitude: 37.7760, longitude: -122.4200) // SF (0.2mi away)
        case "blue-agave":     return CLLocationCoordinate2D(latitude: 37.7800, longitude: -122.4250) // SF (0.8mi away)
        default:               return nil
        }
    }
}

// MARK: - Nearby Badge View

struct NearbyBadge: View {
    let business: SponsorBusiness
    @ObservedObject private var geo = GeoSponsorMatcher.shared

    private var distanceText: String? {
        guard let dist = geo.distanceMiles(to: business) else { return nil }
        if dist < 0.1 { return "Here now" }
        if dist < 1.0 { return "\(String(format: "%.1f", dist * 5280))ft" }
        return "\(String(format: "%.1f", dist))mi"
    }

    var body: some View {
        if geo.locationAuthorized, let dist = distanceText {
            HStack(spacing: 3) {
                Image(systemName: geo.isNearby(business) ? "location.fill" : "location")
                    .font(.system(size: 8))
                Text(dist)
                    .font(.system(size: 8, weight: .bold))
            }
            .foregroundColor(geo.isNearby(business) ? Color(arenza: "#00c9b1") : Color(arenza: "#8892b0"))
            .padding(.horizontal, 5).padding(.vertical, 2)
            .background(geo.isNearby(business) ? Color(arenza: "#00c9b1").opacity(0.12) : Color.white.opacity(0.04))
            .clipShape(Capsule())
        }
    }
}
