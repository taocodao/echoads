// MembershipQRView.swift — Arenza
// Member-facing QR card: shows scannable identity QR + stamp progress + active coupons.
// Swift/SwiftUI port of MemberQRCard.tsx (web demo).
//
// Token auto-refreshes every 5 minutes via a Timer publisher.
// Business selector lets user show card for a specific sponsor.

import SwiftUI
import CoreImage.CIFilterBuiltins
import Combine

// MARK: - Main View

struct MembershipQRView: View {

    @StateObject private var vm = MembershipQRViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                businessSelector
                qrCard
                statsBar
                stampProgress
                activeCouponsSection
                scannerLink
            }
            .padding(16)
        }
        .background(Color(arenza: "#0d0f14").ignoresSafeArea())
        .navigationTitle("My QR Card")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
    }

    // MARK: - Business Selector

    private var businessSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("SHOW CARD FOR")
                .font(.system(size: 9, weight: .black))
                .foregroundColor(Color(arenza: "#8892b0"))
                .tracking(1.2)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // Universal option
                    businessChip(id: "ALL", name: "🌐 Universal")
                    // Per-business options
                    ForEach(Array(businessCatalog.keys.sorted()), id: \.self) { bizId in
                        let info = businessCatalog[bizId]!
                        businessChip(id: bizId, name: "\(info.emoji) \(info.name.components(separatedBy: " ").first ?? info.name)")
                    }
                }
            }
        }
        .padding(14)
        .background(Color(arenza: "#141720"))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func businessChip(id: String, name: String) -> some View {
        Button { vm.selectBusiness(id) } label: {
            Text(name)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(vm.selectedBizId == id ? Color(arenza: "#ff6b35") : Color(arenza: "#8892b0"))
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(arenza: vm.selectedBizId == id ? "#ff6b3522" : "#1a1e2a"))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(arenza: vm.selectedBizId == id ? "#ff6b35" : "#ffffff14"), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - QR Card

    private var qrCard: some View {
        VStack(spacing: 0) {
            // Card header
            HStack(spacing: 12) {
                Text(vm.businessEmoji)
                    .font(.system(size: 28))
                VStack(alignment: .leading, spacing: 2) {
                    Text(vm.businessName)
                        .font(.system(size: 14, weight: .black))
                        .foregroundColor(.white)
                    Text("\(vm.displayName) · \(vm.userId)")
                        .font(.system(size: 10))
                        .foregroundColor(Color(arenza: "#8892b0"))
                }
                Spacer()
                tierBadge
            }
            .padding(14)
            .background(
                LinearGradient(
                    colors: [Color(arenza: "#ff6b3522"), Color(arenza: "#ffc10711")],
                    startPoint: .leading, endPoint: .trailing
                )
            )

            Divider().background(Color.white.opacity(0.08))

            // QR Code
            VStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(arenza: "#1a1e2a"))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(arenza: "#ff6b35").opacity(0.4), lineWidth: 2)
                        )
                        .shadow(color: Color(arenza: "#ff6b35").opacity(0.2), radius: 20)
                        .padding(8)

                    if let qrImage = vm.qrImage {
                        Image(uiImage: qrImage)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 180, height: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    } else {
                        ProgressView()
                            .tint(Color(arenza: "#ff6b35"))
                            .frame(width: 180, height: 180)
                    }
                }
                .frame(width: 200, height: 200)

                // Token preview
                Text(vm.tokenPreview)
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundColor(Color(arenza: "#4a5568"))

                // Refresh countdown
                HStack(spacing: 6) {
                    Circle()
                        .fill(vm.timeLeft < 60 ? Color(arenza: "#ff6b35") : Color(arenza: "#22c55e"))
                        .frame(width: 6, height: 6)
                    Text("Refreshes in \(vm.timeLeftDisplay)")
                        .font(.system(size: 10))
                        .foregroundColor(vm.timeLeft < 60 ? Color(arenza: "#ff6b35") : Color(arenza: "#8892b0"))
                    Button("↻") { vm.refreshToken() }
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(arenza: "#8892b0"))
                }
            }
            .padding(.vertical, 16)

            // Show at counter
            HStack {
                Text("📲 Show this QR code to staff at the counter")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(arenza: "#ff6b35"))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color(arenza: "#ff6b35").opacity(0.08))
        }
        .background(Color(arenza: "#141720"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private var tierBadge: some View {
        Text(vm.membership?.memberTier.rawValue ?? "Guest")
            .font(.system(size: 9, weight: .black))
            .foregroundColor(Color(arenza: vm.membership?.tierColor ?? "#8892b0"))
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(Color(arenza: vm.membership?.tierColor ?? "#8892b0").opacity(0.15))
            .overlay(
                Capsule()
                    .stroke(Color(arenza: vm.membership?.tierColor ?? "#8892b0").opacity(0.4), lineWidth: 1)
            )
            .clipShape(Capsule())
    }

    // MARK: - Stats Bar

    private var statsBar: some View {
        HStack(spacing: 0) {
            statCell(emoji: "🏆", value: "\(vm.membership?.pointsBalance ?? 0)", label: "Points")
            Divider().background(Color.white.opacity(0.08))
            statCell(emoji: "⭐", value: "\(vm.membership?.stamps ?? 0)/\(vm.membership?.stampsRequired ?? 9)", label: "Stamps")
            Divider().background(Color.white.opacity(0.08))
            statCell(emoji: "🎟", value: "\(vm.membership?.activeCouponsFiltered.count ?? 0)", label: "Coupons")
        }
        .background(Color(arenza: "#141720"))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1))
        .fixedSize(horizontal: false, vertical: true)
    }

    private func statCell(emoji: String, value: String, label: String) -> some View {
        VStack(spacing: 3) {
            Text(emoji).font(.system(size: 16))
            Text(value)
                .font(.system(size: 18, weight: .black, design: .monospaced))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 8))
                .foregroundColor(Color(arenza: "#4a5568"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    // MARK: - Stamp Progress

    @ViewBuilder
    private var stampProgress: some View {
        if vm.selectedBizId != "ALL", let biz = vm.membership {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Loyalty Stamps")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(biz.stamps)/\(biz.stampsRequired) — \(biz.stampsRequired - biz.stamps) more to free reward")
                        .font(.system(size: 9))
                        .foregroundColor(Color(arenza: "#8892b0"))
                }

                let cols = Array(repeating: GridItem(.flexible(), spacing: 4), count: biz.stampsRequired)
                LazyVGrid(columns: cols, spacing: 4) {
                    ForEach(0..<biz.stampsRequired, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                i < biz.stamps
                                ? LinearGradient(colors: [Color(arenza: "#ff6b35"), Color(arenza: "#ffc107")], startPoint: .topLeading, endPoint: .bottomTrailing)
                                : LinearGradient(colors: [Color(arenza: "#1a1e2a"), Color(arenza: "#1a1e2a")], startPoint: .top, endPoint: .bottom)
                            )
                            .overlay(
                                Text(i < biz.stamps ? "⭐" : "")
                                    .font(.system(size: 10))
                            )
                            .frame(height: 22)
                    }
                }
            }
            .padding(14)
            .background(Color(arenza: "#141720"))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1))
        }
    }

    // MARK: - Active Coupons

    @ViewBuilder
    private var activeCouponsSection: some View {
        let coupons = vm.membership?.activeCouponsFiltered ?? []
        if !coupons.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("ACTIVE COUPONS (\(coupons.count))")
                    .font(.system(size: 9, weight: .black))
                    .foregroundColor(Color(arenza: "#8892b0"))
                    .tracking(1.2)

                ForEach(coupons) { coupon in
                    HStack(spacing: 10) {
                        Text("🎟").font(.system(size: 16))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(coupon.offer)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                            Text("\(coupon.value) · \(coupon.timeRemainingDisplay)")
                                .font(.system(size: 9))
                                .foregroundColor(Color(arenza: "#8892b0"))
                        }
                        Spacer()
                        Text("VALID")
                            .font(.system(size: 8, weight: .black))
                            .foregroundColor(Color(arenza: "#22c55e"))
                    }
                    .padding(10)
                    .background(Color(arenza: "#22c55e").opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(arenza: "#22c55e").opacity(0.25), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(14)
            .background(Color(arenza: "#141720"))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1))
        }
    }

    // MARK: - Scanner Link (for staff demo)

    private var scannerLink: some View {
        VStack(spacing: 6) {
            Text("Business staff?")
                .font(.system(size: 10))
                .foregroundColor(Color(arenza: "#4a5568"))
            NavigationLink(destination: OperatorScanView()) {
                HStack(spacing: 6) {
                    Image(systemName: "qrcode.viewfinder")
                    Text("Open Business Scanner")
                }
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Color(arenza: "#00c9b1"))
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(Color(arenza: "#00c9b1").opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(arenza: "#00c9b1").opacity(0.4), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - ViewModel

@MainActor
final class MembershipQRViewModel: ObservableObject {

    @Published var selectedBizId: String = "ALL"
    @Published var currentToken: String = ""
    @Published var qrImage: UIImage? = nil
    @Published var timeLeft: Int = 300  // seconds

    private let service = MembershipService.shared
    private var refreshTimer: Timer?
    private var countdownTimer: Timer?

    init() {
        refreshToken()
        startTimers()
    }

    deinit {
        refreshTimer?.invalidate()
        countdownTimer?.invalidate()
    }

    func selectBusiness(_ bizId: String) {
        selectedBizId = bizId
        objectWillChange.send()
        refreshToken()
    }

    func refreshToken() {
        currentToken = ArenzaQRToken.generate(userId: service.userId, businessId: selectedBizId)
        qrImage = generateQRImage(from: currentToken)
        timeLeft = 300
    }

    var membership: BusinessMembership? {
        selectedBizId == "ALL" ? nil : service.getMembership(businessId: selectedBizId)
    }

    var userId: String { service.userId }
    var displayName: String { service.displayName }

    var businessName: String {
        selectedBizId == "ALL" ? "Arenza Universal Card" : businessCatalog[selectedBizId]?.name ?? selectedBizId
    }

    var businessEmoji: String {
        selectedBizId == "ALL" ? "📺" : businessCatalog[selectedBizId]?.emoji ?? "🏪"
    }

    var tokenPreview: String {
        let t = currentToken
        return t.count > 32 ? String(t.prefix(32)) + "..." : t
    }

    var timeLeftDisplay: String {
        let m = timeLeft / 60
        let s = timeLeft % 60
        return "\(m):\(String(format: "%02d", s))"
    }

    // MARK: - Timers

    private func startTimers() {
        // Auto-refresh token every 5 minutes
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 5 * 60, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.refreshToken() }
        }
        // Countdown every second
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if self.timeLeft > 0 { self.timeLeft -= 1 }
            }
        }
    }

    // MARK: - QR Generation (CoreImage)

    private func generateQRImage(from string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"

        guard let output = filter.outputImage else { return nil }

        let scale: CGFloat = 10
        let transform = CGAffineTransform(scaleX: scale, y: scale)
        let scaled = output.transformed(by: transform)

        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

// Color(arenza:) is defined in ArenzaDesignTokens.swift
