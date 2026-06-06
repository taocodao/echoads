// NodeService.swift — Arenza Prototype
// Registers and manages background node contribution tasks.
// In production: this pings the CMXS relay network to signal availability
// and earns contribution rewards (distinct from PoD signing rewards).

import Foundation
import BackgroundTasks

enum NodeService {

    private static let taskIdentifier = "com.cmxs.arenza.node-heartbeat"

    // MARK: - Registration (call from @main init, before app finishes launching)

    static func register() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: taskIdentifier,
            using: .main
        ) { task in
            handleHeartbeat(task: task as! BGAppRefreshTask)
        }
        print("[NodeService] Background task registered: \(taskIdentifier)")
    }

    // MARK: - Schedule

    static func scheduleNextHeartbeat() {
        let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 min

        do {
            try BGTaskScheduler.shared.submit(request)
            print("[NodeService] Next heartbeat scheduled")
        } catch {
            print("[NodeService] Could not schedule heartbeat: \(error)")
        }
    }

    // MARK: - Heartbeat Handler

    private static func handleHeartbeat(task: BGAppRefreshTask) {
        scheduleNextHeartbeat()

        task.expirationHandler = {
            print("[NodeService] Heartbeat expired by OS")
            task.setTaskCompleted(success: false)
        }

        Task {
            await sendHeartbeat()
            task.setTaskCompleted(success: true)
        }
    }

    private static func sendHeartbeat() async {
        // Prototype: just log. Production: POST /api/node/heartbeat
        let walletAddress = WalletDerivation.currentWalletAddress()
        print("[NodeService] ♥ Heartbeat — node: \(WalletDerivation.shortAddress(walletAddress))")

        // In production:
        // let client = CMXSAPIClient()
        // try? await client.sendNodeHeartbeat(walletAddress: walletAddress)
    }
}
