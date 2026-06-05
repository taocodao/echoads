// SGAIShoppableCard.swift — Arenza Prototype
// Interactive shoppable overlay that slides in during ad breaks.
// Proves the SGAI interactive overlay system — highest CPM multiplier.

import SwiftUI

// MARK: - Overlay Data

struct SGAIOverlayData: Identifiable {
    let id = UUID()
    let productName: String
    let productCategory: String
    let priceFormatted: String
    let advertiser: String
    let imageURL: URL?
    let impressionId: String

    // Demo products that rotate per advertiser
    static func demo(for advertiser: String, impressionId: String) -> SGAIOverlayData {
        let products: [(String, String, String, String)] = [
            ("Callaway Paradym Driver", "Golf Equipment", "$549", "https://picsum.photos/seed/golf-driver/120/120"),
            ("Under Armour Curry Flow", "Basketball Shoes", "$160", "https://picsum.photos/seed/curry-shoes/120/120"),
            ("Modelo Especial 12-Pack", "Beverages", "$18.99", "https://picsum.photos/seed/modelo/120/120"),
            ("GoPro HERO12 Black", "Camera", "$399", "https://picsum.photos/seed/gopro/120/120"),
        ]
        let product = products[abs(advertiser.hashValue) % products.count]
        return SGAIOverlayData(
            productName: product.0,
            productCategory: product.1,
            priceFormatted: product.2,
            advertiser: advertiser,
            imageURL: URL(string: product.3),
            impressionId: impressionId
        )
    }
}

// MARK: - Shoppable Card View

struct SGAIShoppableCard: View {
    let data: SGAIOverlayData
    let onDismiss: () -> Void

    @State private var isExpanded = false
    @State private var showBuyConfirmation = false
    @State private var dragOffset: CGFloat = 0
    @State private var opacity: Double = 0

    var body: some View {
        VStack {
            Spacer()
            Group {
                if isExpanded {
                    expandedSheet
                } else {
                    compactCard
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 90)  // above tab bar
        }
        .opacity(opacity)
        .offset(y: dragOffset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    if value.translation.height > 0 {
                        dragOffset = value.translation.height
                    }
                }
                .onEnded { value in
                    if value.translation.height > 60 {
                        dismiss()
                    } else {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            dragOffset = 0
                        }
                    }
                }
        )
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                opacity = 1.0
            }
        }
    }

    // MARK: - Compact Card (default state)

    private var compactCard: some View {
        HStack(spacing: 12) {
            AsyncImage(url: data.imageURL) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fill)
                default:
                    Rectangle().fill(Color(white: 0.2))
                        .overlay(Image(systemName: "bag.fill").foregroundColor(.white.opacity(0.3)))
                }
            }
            .frame(width: 52, height: 52)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 3) {
                Text(data.productName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(data.priceFormatted)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(red: 0.0, green: 0.82, blue: 0.60))
                    Text("· \(data.advertiser)")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                        .lineLimit(1)
                }
            }

            Spacer()

            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    isExpanded = true
                }
            } label: {
                Text("View")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color(red: 0.0, green: 0.82, blue: 0.60))
                    .clipShape(Capsule())
            }
        }
        .padding(14)
        .background(.ultraThinMaterial)
        .background(Color.black.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.4), radius: 12, y: 4)
    }

    // MARK: - Expanded Product Sheet

    private var expandedSheet: some View {
        VStack(spacing: 0) {
            // Handle
            Capsule()
                .fill(Color.white.opacity(0.25))
                .frame(width: 36, height: 4)
                .padding(.top, 12)

            HStack {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isExpanded = false
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                }
                Spacer()
                Text("Featured Product")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 16)

            // Product image
            AsyncImage(url: data.imageURL) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fit)
                default:
                    Rectangle().fill(Color(white: 0.18))
                        .frame(height: 160)
                        .overlay(Image(systemName: "bag.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white.opacity(0.15)))
                }
            }
            .frame(height: 160)
            .padding(.vertical, 20)

            VStack(alignment: .leading, spacing: 8) {
                Text(data.productCategory.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(red: 0.0, green: 0.82, blue: 0.60))
                    .tracking(2)
                Text(data.productName)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                HStack {
                    Text(data.priceFormatted)
                        .font(.system(size: 28, weight: .black))
                        .foregroundColor(.white)
                    Spacer()
                    Text("via \(data.advertiser)")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.45))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)

            // Buy button
            if showBuyConfirmation {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color(red: 0.0, green: 0.82, blue: 0.60))
                    Text("Added to Cart! ✓")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(red: 0.0, green: 0.82, blue: 0.60))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(red: 0.0, green: 0.82, blue: 0.60).opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .transition(.scale.combined(with: .opacity))
            } else {
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        showBuyConfirmation = true
                    }
                    // Auto-dismiss after 1.5s
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                        dismiss()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "apple.logo")
                        Text("Buy with Apple Pay")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }

            Text("Impression ID: \(data.impressionId.prefix(16))...")
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(.white.opacity(0.2))
                .padding(.bottom, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color(white: 0.08).opacity(0.95))
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.25)) {
            opacity = 0
            dragOffset = 120
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            onDismiss()
        }
    }
}
