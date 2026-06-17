// InAppWebView.swift — Arenza
// In-app browser using SFSafariViewController wrapped in SwiftUI.
// Used when user taps "Order", "Visit Website", or "See Menu" on ad cards.
// Shows a real website inside the app without leaving to Safari.

import SwiftUI
import SafariServices

// MARK: - Safari View Controller Wrapper

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false
        let vc = SFSafariViewController(url: url, configuration: config)
        vc.preferredBarTintColor = UIColor(red: 0.05, green: 0.06, blue: 0.08, alpha: 1)
        vc.preferredControlTintColor = UIColor(red: 1.0, green: 0.42, blue: 0.21, alpha: 1) // #ff6b35
        vc.dismissButtonStyle = .done
        return vc
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

// MARK: - In-App Web Sheet

/// Presents a website in a modal sheet using SFSafariViewController.
/// Usage: .sheet(item: $webURL) { url in InAppWebSheet(url: url) }
struct InAppWebSheet: View {
    let url: URL

    var body: some View {
        SafariView(url: url)
            .ignoresSafeArea()
    }
}

/// Identifiable URL wrapper for .sheet(item:)
struct IdentifiableURL: Identifiable {
    let id = UUID()
    let url: URL
}
