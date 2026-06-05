// ArenzaApp.swift
// Arenza — CMXS Sports FAST Channel Viewer
// Entry point for the iOS + tvOS multiplatform app.

import SwiftUI

@main
struct ArenzaApp: App {
    @StateObject private var env = AppEnvironment()

    init() {
        // Register background node contribution task
        NodeService.register()
        // Create / load Secure Enclave signing key on first launch
        SecureEnclaveManager.bootstrap()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(env)
                .preferredColorScheme(.dark)
                .onOpenURL { url in
                    env.router.handleDeepLink(url)
                }
        }
    }
}
