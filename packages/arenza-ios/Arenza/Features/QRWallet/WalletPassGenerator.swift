// WalletPassGenerator.swift — Arenza
// Phase 2: Apple Wallet (PassKit) integration.
// Generates member card and reward coupon passes for Apple Wallet.
//
// Pass Types:
//   - Store Card  → MemberCard (loyalty points, tier, QR code)
//   - Coupon      → SpinReward (time-limited reward, QR code)
//
// Note: Actual .pkpass signing requires a server-side certificate.
// This file handles the client-side PKPass presentation and the
// "Add to Wallet" button flow. The generatePass() call posts to
// our backend which signs and returns the .pkpass blob.
//
// GAP 3 from the optimization plan — 80% save rate vs 22% app download.

import Foundation
import PassKit
import SwiftUI

// MARK: - Wallet Pass Generator

@MainActor
final class WalletPassGenerator: NSObject, ObservableObject {

    static let shared = WalletPassGenerator()

    @Published var isAddingToWallet: Bool = false
    @Published var lastAddedPassType: PassType? = nil
    @Published var errorMessage: String? = nil

    enum PassType { case memberCard, reward }

    // MARK: - Availability

    /// Whether the device supports Apple Wallet
    var isWalletAvailable: Bool {
        PKPassLibrary.isPassLibraryAvailable()
    }

    // MARK: - Add Member Card to Wallet

    func addMemberCard(_ card: MemberCard) async {
        guard isWalletAvailable else {
            errorMessage = "Apple Wallet is not available on this device."
            return
        }

        isAddingToWallet = true
        defer { isAddingToWallet = false }

        // 1. Request pass from backend
        do {
            let passData = try await fetchPassFromBackend(for: .memberCard, payload: memberCardPassPayload(card))
            await presentPass(passData, type: .memberCard)
        } catch {
            // Demo fallback: show the Wallet UI with a placeholder message
            errorMessage = "Pass signing requires the Arenza server (demo mode). Your QR wallet is still active."
        }
    }

    // MARK: - Add Reward to Wallet

    func addReward(_ reward: SpinReward) async {
        guard isWalletAvailable else {
            errorMessage = "Apple Wallet is not available on this device."
            return
        }
        guard reward.isValid else {
            errorMessage = "This reward has already been used or expired."
            return
        }

        isAddingToWallet = true
        defer { isAddingToWallet = false }

        do {
            let passData = try await fetchPassFromBackend(for: .reward, payload: rewardPassPayload(reward))
            await presentPass(passData, type: .reward)
        } catch {
            errorMessage = "Pass signing requires the Arenza server (demo mode). Your QR wallet is still active."
        }
    }

    // MARK: - Pass Payload Construction

    private func memberCardPassPayload(_ card: MemberCard) -> [String: Any] {
        [
            "passType": "storeCard",
            "serialNumber": card.memberId,
            "sponsorId": card.sponsorId,
            "sponsorName": card.sponsorName,
            "memberTier": card.tierLabel,
            "totalPoints": card.totalPoints,
            "qrPayload": card.qrPayload,
            "brandColor": card.sponsorBrandColor,
            "labelColor": "#FFFFFF",
            "foregroundColor": "#FFFFFF"
        ]
    }

    private func rewardPassPayload(_ reward: SpinReward) -> [String: Any] {
        [
            "passType": "coupon",
            "serialNumber": reward.rewardCode,
            "sponsorId": reward.sponsorId,
            "sponsorName": reward.sponsorName,
            "rewardLabel": reward.rewardLabel,
            "rewardValue": reward.rewardValue,
            "expiresAt": Int(reward.expiresAt.timeIntervalSince1970),
            "qrPayload": reward.qrPayload,
            "brandColor": reward.sponsorBrandColor
        ]
    }

    // MARK: - Backend Pass Signing

    private func fetchPassFromBackend(for type: PassType, payload: [String: Any]) async throws -> Data {
        guard let url = URL(string: "https://api.arenza.app/v1/wallet/pass") else {
            throw WalletError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        request.timeoutInterval = 10

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw WalletError.signingFailed
        }
        return data
    }

    // MARK: - Present PKPass

    @MainActor
    private func presentPass(_ passData: Data, type: PassType) async {
        do {
            let pass = try PKPass(data: passData)
            let vc = PKAddPassesViewController(pass: pass)!
            vc.delegate = self

            // Present from root view controller
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let root = windowScene.windows.first?.rootViewController {
                var presented = root
                while let p = presented.presentedViewController { presented = p }
                presented.present(vc, animated: true)
                lastAddedPassType = type
            }
        } catch {
            errorMessage = "Could not load pass: \(error.localizedDescription)"
        }
    }
}

// MARK: - PKAddPassesViewControllerDelegate

extension WalletPassGenerator: PKAddPassesViewControllerDelegate {
    nonisolated func addPassesViewControllerDidFinish(_ controller: PKAddPassesViewController) {
        controller.dismiss(animated: true)
        Task { @MainActor in
            WalletPassGenerator.shared.lastAddedPassType = nil
        }
    }
}

// MARK: - Wallet Errors

enum WalletError: LocalizedError {
    case invalidURL
    case signingFailed
    case notAvailable

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid pass URL."
        case .signingFailed: return "Pass signing failed. Check server connectivity."
        case .notAvailable: return "Apple Wallet is not available on this device."
        }
    }
}

// MARK: - Add to Wallet Button (SwiftUI)

struct AddToWalletButton: View {
    let action: () async -> Void
    @ObservedObject private var generator = WalletPassGenerator.shared
    @State private var showError = false

    var body: some View {
        Button {
            Task { await action() }
        } label: {
            HStack(spacing: 8) {
                if generator.isAddingToWallet {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "wallet.pass.fill")
                        .font(.system(size: 14))
                }
                Text(generator.isAddingToWallet ? "Adding..." : "Add to Apple Wallet")
                    .font(.system(size: 13, weight: .bold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                LinearGradient(
                    colors: [Color(arenza: "#1a1a2e"), Color(arenza: "#16213e")],
                    startPoint: .leading, endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(generator.isAddingToWallet || !generator.isWalletAvailable)
        .opacity(generator.isWalletAvailable ? 1.0 : 0.4)
        .alert("Wallet Note", isPresented: $showError, presenting: generator.errorMessage) { _ in
            Button("OK") { generator.errorMessage = nil }
        } message: { msg in
            Text(msg)
        }
        .onChange(of: generator.errorMessage) { msg in
            showError = msg != nil
        }
    }
}
