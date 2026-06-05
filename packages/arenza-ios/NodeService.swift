// NodeService.swift
// Background DePIN node contribution via BGProcessingTask.
// Sends heartbeats to CMXS node service every 15 minutes while app is backgrounded.

import BackgroundTasks
import Foundation

final class NodeService {

    static let taskIdentifier = "com.cmxs.arenza.node-contribution"

    // Call from AppDelegate / @main init
    static func register() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: taskIdentifier,
            using: nil
        ) { task in
            handleTask(task as! BGProcessingTask)
        }
    }

    static func schedule() {
        let request = BGProcessingTaskRequest(identifier: taskIdentifier)
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        try? BGTaskScheduler.shared.submit(request)
        print("[Node] Background task scheduled")
    }

    private static func handleTask(_ task: BGProcessingTask) {
        task.expirationHandler = { task.setTaskCompleted(success: false) }

        Task {
            print("[Node] Sending heartbeat…")
            // In production: call POST /node/heartbeat
            // try await CMXSAPIClient().post("/node/heartbeat", body: [...])
            try? await Task.sleep(nanoseconds: 200_000_000)
            task.setTaskCompleted(success: true)
            schedule()   // Reschedule
        }
    }
}
