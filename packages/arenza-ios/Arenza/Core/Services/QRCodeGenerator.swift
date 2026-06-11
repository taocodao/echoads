// QRCodeGenerator.swift — Arenza (TableSpin Integration)
// CoreImage-based QR code generation. Zero third-party dependencies.

import SwiftUI
import CoreImage.CIFilterBuiltins

struct QRCodeGenerator {

    static func generate(from string: String, size: CGFloat = 200) -> UIImage {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        guard let data = string.data(using: .utf8) else { return UIImage() }

        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")

        guard let ciImage = filter.outputImage else { return UIImage() }

        // Scale to target size
        let scaleX = size / ciImage.extent.size.width
        let scaleY = size / ciImage.extent.size.height
        let scaled = ciImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return UIImage() }
        return UIImage(cgImage: cgImage)
    }

    static func swiftUIImage(from string: String, size: CGFloat = 200) -> Image {
        Image(uiImage: generate(from: string, size: size))
            .interpolation(.none)
    }
}

// MARK: - QR Code View

struct QRCodeView: View {
    let payload: String
    let size: CGFloat
    let foregroundColor: Color
    let backgroundColor: Color

    init(
        payload: String,
        size: CGFloat = 160,
        foreground: Color = .black,
        background: Color = .white
    ) {
        self.payload = payload
        self.size = size
        self.foregroundColor = foreground
        self.backgroundColor = background
    }

    var body: some View {
        let uiImage = QRCodeGenerator.generate(from: payload, size: size)
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(backgroundColor)
                .frame(width: size + 20, height: size + 20)

            Image(uiImage: uiImage)
                .interpolation(.none)
                .resizable()
                .frame(width: size, height: size)
                .colorMultiply(foregroundColor)
        }
    }
}
