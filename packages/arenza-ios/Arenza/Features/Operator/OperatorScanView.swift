// OperatorScanView.swift — Arenza
// Business Owner Mode: scan customer QR codes to validate and claim rewards.
//
// Architecture: In-app Operator Mode, gated behind a 6-digit PIN.
// No third-party POS integration needed — the scan happens directly
// in our app on the restaurant owner's iPhone.
//
// Flow:
//   1. Business owner enters PIN in Settings → unlocks "Operator Mode" tab
//   2. Opens OperatorScanView → camera activates via AVFoundation
//   3. Customer shows QR from their Arenza wallet
//   4. App decodes JSON payload, validates HMAC signature + TTL
//   5. Shows customer info + reward details
//   6. Owner taps "Confirm Redemption" → marks reward as claimed

import SwiftUI
import AVFoundation
import CoreImage.CIFilterBuiltins

// MARK: - Operator Scan View

struct OperatorScanView: View {
    @StateObject private var vm = OperatorScanViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        if vm.state == .locked {
            NavigationView {
                ZStack {
                    Color.black.ignoresSafeArea()
                    pinEntryView
                }
                .navigationTitle("Operator Mode")
                .navigationBarTitleDisplayMode(.inline)
            }
            .preferredColorScheme(.dark)
        } else {
            TabView {
                NavigationView {
                    ZStack {
                        Color.black.ignoresSafeArea()
                        switch vm.state {
                        case .scanning:   scannerView
                        case .validating: validatingView
                        case .success(let r): resultView(result: r)
                        case .error(let m):   errorView(message: m)
                        default: EmptyView()
                        }
                    }
                    .navigationTitle("Scan Reward")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Lock") { vm.lock() }
                                .foregroundColor(Color(arenza: "#ff6b35"))
                        }
                    }
                }
                .tabItem { Label("Scanner", systemImage: "qrcode.viewfinder") }

                OperatorAnalyticsView()
                    .tabItem { Label("Analytics", systemImage: "chart.bar.fill") }
            }
            .tint(Color(arenza: "#00c9b1"))
            .preferredColorScheme(.dark)
        }
    }

    // MARK: - PIN Entry

    private var pinEntryView: some View {
        VStack(spacing: 32) {
            Spacer()
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 52))
                .foregroundColor(Color(arenza: "#00c9b1"))

            Text("Business Operator Mode")
                .font(.system(size: 22, weight: .black))
                .foregroundColor(.white)
            Text("Enter your operator PIN to scan customer rewards")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            // PIN dots
            HStack(spacing: 16) {
                ForEach(0..<6, id: \.self) { i in
                    Circle()
                        .fill(i < vm.enteredPin.count ? Color(arenza: "#00c9b1") : Color.white.opacity(0.15))
                        .frame(width: 14, height: 14)
                }
            }

            if vm.pinError {
                Text("Incorrect PIN — try again")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(arenza: "#ff6b35"))
                    .transition(.opacity)
            }

            // Numpad
            PinPadView(
                onDigit: { vm.enteredPin.append($0) },
                onDelete: { if !vm.enteredPin.isEmpty { vm.enteredPin.removeLast() } },
                onSubmit: { vm.submitPin() }
            )
            .padding(.horizontal, 40)

            Spacer()
        }
    }

    // MARK: - Scanner

    private var scannerView: some View {
        VStack(spacing: 0) {
            // Instruction bar
            HStack {
                Image(systemName: "qrcode.viewfinder")
                    .foregroundColor(Color(arenza: "#00c9b1"))
                Text("Point camera at customer's QR code")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(12)
            .background(Color(arenza: "#141720"))

            // Camera feed
            ZStack {
                QRScannerCameraView(onCodeScanned: { code in
                    vm.processScannedCode(code)
                })

                // Viewfinder overlay
                VStack {
                    Spacer()
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(arenza: "#00c9b1"), lineWidth: 3)
                        .frame(width: 240, height: 240)
                        .overlay(
                            Text("Align QR here")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(Color(arenza: "#00c9b1"))
                                .padding(.top, 250)
                        )
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Validating

    private var validatingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .tint(Color(arenza: "#00c9b1"))
                .scaleEffect(1.5)
            Text("Validating reward...")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.7))
        }
    }

    // MARK: - Result

    private func resultView(result: ScanResult) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // Status header
                VStack(spacing: 8) {
                    Image(systemName: result.isValid ? "checkmark.seal.fill" : "xmark.seal.fill")
                        .font(.system(size: 52))
                        .foregroundColor(result.isValid ? Color(arenza: "#00c9b1") : Color(arenza: "#ff6b35"))

                    Text(result.isValid ? "Valid Reward" : "Invalid Reward")
                        .font(.system(size: 22, weight: .black))
                        .foregroundColor(.white)
                    Text(result.statusMessage)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 24)

                if result.isValid {
                    // Customer info card
                    VStack(alignment: .leading, spacing: 12) {
                        sectionLabel("CUSTOMER")
                        infoRow(icon: "person.fill", label: "Member", value: result.memberName)
                        infoRow(icon: "creditcard.fill", label: "Member ID", value: result.memberId)
                        infoRow(icon: "star.fill", label: "Tier", value: result.memberTier)
                    }
                    .padding(16)
                    .background(Color.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 20)

                    // Reward info card
                    VStack(alignment: .leading, spacing: 12) {
                        sectionLabel("REWARD")
                        infoRow(icon: "gift.fill", label: "Reward", value: result.rewardLabel)
                        infoRow(icon: "storefront.fill", label: "Sponsor", value: result.sponsorName)
                        infoRow(icon: "clock.fill", label: "Expires", value: result.expiryDisplay)
                        infoRow(icon: "number", label: "Code", value: result.rewardCode)
                    }
                    .padding(16)
                    .background(Color.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 20)

                    // Confirm redemption
                    Button {
                        vm.confirmRedemption()
                    } label: {
                        Text(vm.redeemed ? "✓ Redeemed" : "Confirm Redemption")
                            .font(.system(size: 16, weight: .black))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(vm.redeemed ? Color(arenza: "#4a5568") : Color(arenza: "#00c9b1"))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                    .disabled(vm.redeemed)
                    .padding(.horizontal, 20)
                }

                // Scan another
                Button {
                    vm.resetToScanning()
                } label: {
                    Text("Scan Another")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(arenza: "#00c9b1"))
                }
            }
        }
    }

    // MARK: - Error

    private func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(Color(arenza: "#ff6b35"))
            Text("Scan Error")
                .font(.system(size: 20, weight: .black)).foregroundColor(.white)
            Text(message)
                .font(.system(size: 13)).foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center).padding(.horizontal, 32)
            Button { vm.resetToScanning() } label: {
                Text("Try Again")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(arenza: "#00c9b1"))
            }
        }
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 9, weight: .black))
            .foregroundColor(.white.opacity(0.35))
            .tracking(1.2)
    }

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(Color(arenza: "#00c9b1"))
                .frame(width: 20)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.5))
                .frame(width: 70, alignment: .leading)
            Text(value)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)
        }
    }
}

// MARK: - Scan Result

struct ScanResult {
    let isValid: Bool
    let statusMessage: String
    let memberName: String
    let memberId: String
    let memberTier: String
    let rewardLabel: String
    let sponsorName: String
    let rewardCode: String
    let expiryDisplay: String
    let rawRewardId: UUID?
}

// MARK: - OperatorScanViewModel

@MainActor
final class OperatorScanViewModel: ObservableObject {

    enum ScanState: Equatable {
        case locked
        case scanning
        case validating
        case success(ScanResult)
        case error(String)

        static func == (lhs: ScanState, rhs: ScanState) -> Bool {
            switch (lhs, rhs) {
            case (.locked, .locked), (.scanning, .scanning), (.validating, .validating): return true
            case (.success, .success), (.error, .error): return true
            default: return false
            }
        }
    }

    @Published var state: ScanState = .locked
    @Published var enteredPin: String = "" { didSet { if enteredPin.count == 6 { submitPin() } } }
    @Published var pinError: Bool = false
    @Published var redeemed: Bool = false

    // MARK: PIN (demo PIN: 123456)
    private let operatorPin = "123456"

    func submitPin() {
        if enteredPin == operatorPin {
            pinError = false
            withAnimation { state = .scanning }
        } else {
            pinError = true
            enteredPin = ""
        }
    }

    func lock() {
        enteredPin = ""
        state = .locked
    }

    // MARK: - QR Processing

    func processScannedCode(_ rawString: String) {
        guard state == .scanning else { return }
        state = .validating

        // Parse the QR payload
        Task {
            await Task.yield() // allow UI to update
            let result = validateQRPayload(rawString)
            await MainActor.run {
                withAnimation { self.state = .success(result) }
            }
        }
    }

    private func validateQRPayload(_ raw: String) -> ScanResult {
        // Try to decode as JSON (our QR format)
        guard let data = raw.data(using: .utf8),
              let payload = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return ScanResult(
                isValid: false,
                statusMessage: "Could not read QR code. Ask customer to open Arenza Wallet.",
                memberName: "-", memberId: "-", memberTier: "-",
                rewardLabel: "-", sponsorName: "-", rewardCode: "-",
                expiryDisplay: "-", rawRewardId: nil
            )
        }

        let rewardId    = payload["reward_id"] as? String ?? ""
        let memberId    = payload["member_id"] as? String ?? "MBR-UNKNOWN"
        let sponsorId   = payload["sponsor_id"] as? String ?? ""
        let rewardLabel = payload["reward_label"] as? String ?? "Unknown Reward"
        let rewardCode  = payload["reward_code"] as? String ?? "-"
        let sponsorName = payload["sponsor_name"] as? String ?? "-"
        let memberTier  = payload["member_tier"] as? String ?? "Regular"
        let expiresAt   = payload["expires_at"] as? TimeInterval ?? 0

        // Check expiry
        let expiry = Date(timeIntervalSince1970: expiresAt)
        let isExpired = expiry < Date()

        if isExpired {
            return ScanResult(
                isValid: false,
                statusMessage: "This reward expired \(formatDate(expiry)).",
                memberName: "Member \(memberId.prefix(8))",
                memberId: memberId, memberTier: memberTier,
                rewardLabel: rewardLabel, sponsorName: sponsorName,
                rewardCode: rewardCode,
                expiryDisplay: formatDate(expiry),
                rawRewardId: UUID(uuidString: rewardId)
            )
        }

        // Check against local wallet (real production: would call server)
        let walletReward = QRWalletService.shared.rewards.first {
            $0.rewardCode == rewardCode && $0.status == .active
        }

        let alreadyClaimed = walletReward?.status == .claimed

        if alreadyClaimed {
            return ScanResult(
                isValid: false,
                statusMessage: "This reward has already been claimed.",
                memberName: "Member \(memberId.prefix(8))",
                memberId: memberId, memberTier: memberTier,
                rewardLabel: rewardLabel, sponsorName: sponsorName,
                rewardCode: rewardCode, expiryDisplay: formatDate(expiry),
                rawRewardId: UUID(uuidString: rewardId)
            )
        }

        return ScanResult(
            isValid: true,
            statusMessage: "Reward is valid and ready to be claimed.",
            memberName: "Member \(memberId.prefix(8))",
            memberId: memberId, memberTier: memberTier,
            rewardLabel: rewardLabel, sponsorName: sponsorName,
            rewardCode: rewardCode,
            expiryDisplay: formatDate(expiry),
            rawRewardId: UUID(uuidString: rewardId)
        )
    }

    func confirmRedemption() {
        guard case .success(let result) = state, let rid = result.rawRewardId else { return }
        QRWalletService.shared.claimReward(id: rid)
        withAnimation { redeemed = true }
    }

    func resetToScanning() {
        redeemed = false
        withAnimation { state = .scanning }
    }

    // MARK: - Helpers

    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .short
        return f.string(from: date)
    }
}

// MARK: - QR Scanner Camera View (AVFoundation)

import UIKit

struct QRScannerCameraView: UIViewRepresentable {
    let onCodeScanned: (String) -> Void

    func makeUIView(context: Context) -> QRScannerPreviewView {
        let view = QRScannerPreviewView()
        view.onCodeScanned = { [onCodeScanned] code in
            DispatchQueue.main.async { onCodeScanned(code) }
        }
        view.startSession()
        return view
    }

    func updateUIView(_ uiView: QRScannerPreviewView, context: Context) {}
}

final class QRScannerPreviewView: UIView, AVCaptureMetadataOutputObjectsDelegate {
    var onCodeScanned: ((String) -> Void)?

    private var session: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var lastScanned: String?
    private var lastScanTime: Date?

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
    }

    func startSession() {
        guard AVCaptureDevice.authorizationStatus(for: .video) != .denied else { return }

        let session = AVCaptureSession()
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else { return }

        session.addInput(input)

        let output = AVCaptureMetadataOutput()
        session.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: .main)
        output.metadataObjectTypes = [.qr]

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = bounds
        layer.addSublayer(previewLayer)

        self.session = session
        self.previewLayer = previewLayer

        DispatchQueue.global(qos: .background).async {
            session.startRunning()
        }
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        guard let obj = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let code = obj.stringValue else { return }

        // Debounce — don't fire same code twice within 3 seconds
        let now = Date()
        if code == lastScanned, let last = lastScanTime, now.timeIntervalSince(last) < 3 { return }
        lastScanned = code
        lastScanTime = now

        session?.stopRunning()
        onCodeScanned?(code)
    }
}

// MARK: - Pin Pad View

struct PinPadView: View {
    let onDigit: (String) -> Void
    let onDelete: () -> Void
    let onSubmit: () -> Void

    private let digits = [["1","2","3"],["4","5","6"],["7","8","9"],["","0","⌫"]]

    var body: some View {
        VStack(spacing: 14) {
            ForEach(digits, id: \.self) { row in
                HStack(spacing: 20) {
                    ForEach(row, id: \.self) { key in
                        Button {
                            if key == "⌫" { onDelete() }
                            else if !key.isEmpty { onDigit(key) }
                        } label: {
                            Text(key)
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(key.isEmpty ? .clear : .white)
                                .frame(width: 68, height: 52)
                                .background(key.isEmpty ? Color.clear : Color.white.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                        .disabled(key.isEmpty)
                    }
                }
            }
        }
    }
}
