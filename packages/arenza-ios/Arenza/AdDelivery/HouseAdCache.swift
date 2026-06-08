// HouseAdCache.swift — Arenza (C2: Ad Delivery Pipeline)
// Pre-downloads house ad creatives for zero-black-screen fallback.
// Registered as BGProcessingTask: com.arenza.housead.refresh

import Foundation
import BackgroundTasks

// MARK: - House Ad Cache

@MainActor
final class HouseAdCache: ObservableObject {

    static let shared = HouseAdCache()

    @Published private(set) var cachedAds: [HouseAd] = []
    @Published private(set) var isRefreshing: Bool = false

    private let cacheDirectory: URL
    private let maxCacheSizeBytes: Int = 200 * 1024 * 1024  // 200 MB
    private let session = URLSession.shared

    private init() {
        let docs = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        cacheDirectory = docs.appendingPathComponent("HouseAds", isDirectory: true)
        try? FileManager.default.createDirectory(at: cacheDirectory,
                                                  withIntermediateDirectories: true)
        loadFromDisk()
    }

    // MARK: - Next available house ad (excluding used advertisers)

    func nextHouseAd(excluding advertisers: Set<String> = []) -> HouseAd? {
        cachedAds
            .filter { $0.isValid && !advertisers.contains($0.advertiserID) }
            .randomElement()
    }

    // MARK: - Refresh (called from BGProcessingTask or on first launch)

    func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        // Load demo house ads when backend is not yet available
        #if DEBUG
        await loadDemoAds()
        #else
        await fetchAndCacheFromAPI()
        #endif
    }

    // MARK: - Demo ads (used in DEBUG / until backend is live)

    private func loadDemoAds() async {
        let demos: [HouseAd] = [
            HouseAd(
                id: "house-001",
                advertiserID: "cmxs_promo",
                advertiserName: "CMXS Network",
                creativeURL: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4")!,
                localFileURL: nil,
                durationSeconds: 15,
                expiresAt: Date().addingTimeInterval(86400 * 7)
            ),
            HouseAd(
                id: "house-002",
                advertiserID: "arenza_app",
                advertiserName: "Arenza — Watch Live Sports",
                creativeURL: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4")!,
                localFileURL: nil,
                durationSeconds: 30,
                expiresAt: Date().addingTimeInterval(86400 * 7)
            )
        ]
        cachedAds = demos
        print("[HouseAdCache] ✅ Loaded \(demos.count) demo house ads")
    }

    // MARK: - Production fetch from CMXS API

    private func fetchAndCacheFromAPI() async {
        guard let url = URL(string: "\(CMXSConfig.apiBase)/v1/house-ads") else { return }

        do {
            let (data, _) = try await session.data(from: url)
            let ads = try JSONDecoder().decode([HouseAd].self, from: data)

            // Download creatives locally
            var cached: [HouseAd] = []
            for var ad in ads {
                let localURL = cacheDirectory.appendingPathComponent("\(ad.id).mp4")
                if !FileManager.default.fileExists(atPath: localURL.path) {
                    try? await downloadCreative(from: ad.creativeURL, to: localURL)
                }
                if FileManager.default.fileExists(atPath: localURL.path) {
                    ad = HouseAd(
                        id: ad.id, advertiserID: ad.advertiserID,
                        advertiserName: ad.advertiserName, creativeURL: ad.creativeURL,
                        localFileURL: localURL, durationSeconds: ad.durationSeconds,
                        expiresAt: ad.expiresAt
                    )
                }
                cached.append(ad)
            }

            // Evict expired
            cachedAds = cached.filter { $0.isValid }
            saveToDisk()
            enforceCacheSizeLimit()
            print("[HouseAdCache] ✅ Cached \(cachedAds.count) house ads")
        } catch {
            print("[HouseAdCache] ❌ Refresh failed: \(error.localizedDescription)")
        }
    }

    private func downloadCreative(from remoteURL: URL, to localURL: URL) async throws {
        let (tempURL, _) = try await session.download(from: remoteURL)
        try FileManager.default.moveItem(at: tempURL, to: localURL)
    }

    // MARK: - Disk persistence (metadata only — files stay in cacheDir)

    private func saveToDisk() {
        let metaURL = cacheDirectory.appendingPathComponent("meta.json")
        if let data = try? JSONEncoder().encode(cachedAds) {
            try? data.write(to: metaURL)
        }
    }

    private func loadFromDisk() {
        let metaURL = cacheDirectory.appendingPathComponent("meta.json")
        guard let data = try? Data(contentsOf: metaURL),
              let ads = try? JSONDecoder().decode([HouseAd].self, from: data) else { return }
        cachedAds = ads.filter { $0.isValid }
    }

    // MARK: - LRU cache eviction

    private func enforceCacheSizeLimit() {
        var totalBytes = 0
        for file in (try? FileManager.default.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: [.fileSizeKey],
            options: .skipsHiddenFiles
        )) ?? [] {
            let size = (try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            totalBytes += size
        }

        if totalBytes > maxCacheSizeBytes {
            // Evict oldest file
            let files = (try? FileManager.default.contentsOfDirectory(
                at: cacheDirectory,
                includingPropertiesForKeys: [.contentModificationDateKey],
                options: .skipsHiddenFiles
            ))?.sorted(by: {
                let d1 = (try? $0.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantFuture
                let d2 = (try? $1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantFuture
                return d1 < d2
            }) ?? []

            if let oldest = files.first {
                try? FileManager.default.removeItem(at: oldest)
                print("[HouseAdCache] Evicted \(oldest.lastPathComponent)")
            }
        }
    }
}

// MARK: - BGProcessingTask Registration (call from ArenzaApp)

enum HouseAdBGTask {
    static let identifier = "com.arenza.housead.refresh"

    static func register() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: identifier, using: nil) { task in
            guard let processingTask = task as? BGProcessingTask else { return }
            Task {
                await HouseAdCache.shared.refresh()
                processingTask.setTaskCompleted(success: true)
            }
            processingTask.expirationHandler = {
                processingTask.setTaskCompleted(success: false)
            }
        }
    }

    static func schedule() {
        let request = BGProcessingTaskRequest(identifier: identifier)
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = true     // charge + Wi-Fi = ideal
        request.earliestBeginDate = Date(timeIntervalSinceNow: 3600)
        try? BGTaskScheduler.shared.submit(request)
    }
}
