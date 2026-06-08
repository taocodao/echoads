// GeoComplianceService.swift — Arenza (C6: Betting Engine)
// Determines whether the user is in a US state with legal online sports betting.
// Uses CoreLocation + static state list. Does NOT transmit location to any server.

import Foundation
import CoreLocation
import Combine

// MARK: - Geo Compliance Service

@MainActor
final class GeoComplianceService: NSObject, ObservableObject, CLLocationManagerDelegate {

    static let shared = GeoComplianceService()

    @Published private(set) var currentState: String?           // 2-letter code, e.g. "NY"
    @Published private(set) var isBettingLegalHere: Bool = false
    @Published private(set) var geoStatus: GeoStatus = .unknown

    enum GeoStatus {
        case unknown, checking, legal, illegal, permissionDenied, error
    }

    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var lastCheckDate: Date?

    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer  // state-level only
    }

    // MARK: - Check (call before showing any betting UI)

    func checkCompliance() async -> Bool {
        // Cache result for 30 minutes — avoid repeated location checks
        if let last = lastCheckDate, Date().timeIntervalSince(last) < 1800 {
            return isBettingLegalHere
        }

        geoStatus = .checking

        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            return await resolveStateFromLocation()
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            return false  // Caller should retry after permission granted
        case .denied, .restricted:
            geoStatus = .permissionDenied
            isBettingLegalHere = false
            return false
        @unknown default:
            return false
        }
    }

    // MARK: - Resolve state from device location

    private func resolveStateFromLocation() async -> Bool {
        guard let location = locationManager.location else {
            geoStatus = .error
            return false
        }

        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            if let state = placemarks.first?.administrativeArea {
                // CLGeocoder returns full state name for US; convert to 2-letter
                let stateCode = USStateMap.code(for: state)
                currentState = stateCode
                let isLegal = legalBettingStates.contains(stateCode ?? "")
                isBettingLegalHere = isLegal
                geoStatus = isLegal ? .legal : .illegal
                lastCheckDate = Date()
                print("[GeoCompliance] State: \(stateCode ?? state) — Betting \(isLegal ? "✅ legal" : "❌ not legal")")
                return isLegal
            }
        } catch {
            print("[GeoCompliance] Geocode error: \(error.localizedDescription)")
            geoStatus = .error
        }
        return false
    }

    // MARK: - CLLocationManagerDelegate

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            if manager.authorizationStatus == .authorizedWhenInUse ||
               manager.authorizationStatus == .authorizedAlways {
                _ = await self.resolveStateFromLocation()
            }
        }
    }
}

// MARK: - US State Name → Code map (subset of commonly mis-geocoded states)

enum USStateMap {
    static func code(for fullName: String) -> String? {
        let map: [String: String] = [
            "Alabama": "AL", "Alaska": "AK", "Arizona": "AZ", "Arkansas": "AR",
            "California": "CA", "Colorado": "CO", "Connecticut": "CT", "Delaware": "DE",
            "Florida": "FL", "Georgia": "GA", "Hawaii": "HI", "Idaho": "ID",
            "Illinois": "IL", "Indiana": "IN", "Iowa": "IA", "Kansas": "KS",
            "Kentucky": "KY", "Louisiana": "LA", "Maine": "ME", "Maryland": "MD",
            "Massachusetts": "MA", "Michigan": "MI", "Minnesota": "MN", "Mississippi": "MS",
            "Missouri": "MO", "Montana": "MT", "Nebraska": "NE", "Nevada": "NV",
            "New Hampshire": "NH", "New Jersey": "NJ", "New Mexico": "NM", "New York": "NY",
            "North Carolina": "NC", "North Dakota": "ND", "Ohio": "OH", "Oklahoma": "OK",
            "Oregon": "OR", "Pennsylvania": "PA", "Rhode Island": "RI", "South Carolina": "SC",
            "South Dakota": "SD", "Tennessee": "TN", "Texas": "TX", "Utah": "UT",
            "Vermont": "VT", "Virginia": "VA", "Washington": "WA", "West Virginia": "WV",
            "Wisconsin": "WI", "Wyoming": "WY", "District of Columbia": "DC",
            "Puerto Rico": "PR"
        ]
        return map[fullName] ?? (fullName.count == 2 ? fullName : nil)
    }
}
