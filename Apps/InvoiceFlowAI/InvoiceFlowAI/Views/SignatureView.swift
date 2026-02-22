import SwiftUI
import PencilKit

// MARK: - Signature Capture View

struct SignatureCaptureView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var signatureData: Data?
    @State private var canvasView = PKCanvasView()
    @State private var showingClearConfirmation = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Instructions
                HStack {
                    Image(systemName: "hand.draw.fill")
                        .font(.title2)
                        .foregroundColor(.green)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Draw Your Signature")
                            .font(.headline)
                        Text("Use your finger or Apple Pencil")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
                .padding()
                .background(Color(.secondarySystemBackground))

                // Signature Canvas
                SignatureCanvas(canvasView: $canvasView)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 0)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )

                // Signature Line
                VStack(spacing: 4) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.5))
                        .frame(height: 1)
                        .padding(.horizontal, 40)

                    Text("Sign above the line")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, -40)
                .padding(.bottom, 20)

                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: saveSignature) {
                        Label("Save Signature", systemImage: "checkmark.circle.fill")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(12)
                    }

                    HStack(spacing: 12) {
                        Button(action: { showingClearConfirmation = true }) {
                            Label("Clear", systemImage: "trash")
                                .font(.subheadline)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(12)
                        }

                        Button(action: { dismiss() }) {
                            Label("Cancel", systemImage: "xmark")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(12)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Signature")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .confirmationDialog("Clear Signature?", isPresented: $showingClearConfirmation) {
                Button("Clear", role: .destructive) {
                    canvasView.drawing = PKDrawing()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will clear the current signature.")
            }
        }
    }

    private func saveSignature() {
        let image = canvasView.drawing.image(
            from: canvasView.bounds,
            scale: UIScreen.main.scale
        )

        // Trim whitespace and create a clean signature image
        if let trimmedImage = trimWhitespace(from: image),
           let pngData = trimmedImage.pngData() {
            signatureData = pngData
        }

        dismiss()
    }

    private func trimWhitespace(from image: UIImage) -> UIImage? {
        guard let cgImage = image.cgImage else { return image }

        let width = cgImage.width
        let height = cgImage.height

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return image }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        guard let pixelData = context.data else { return image }

        let data = pixelData.bindMemory(to: UInt8.self, capacity: width * height * bytesPerPixel)

        var minX = width
        var minY = height
        var maxX = 0
        var maxY = 0

        for y in 0..<height {
            for x in 0..<width {
                let pixelIndex = (y * width + x) * bytesPerPixel
                let alpha = data[pixelIndex + 3]

                if alpha > 0 {
                    minX = min(minX, x)
                    minY = min(minY, y)
                    maxX = max(maxX, x)
                    maxY = max(maxY, y)
                }
            }
        }

        // Add some padding
        let padding = 10
        minX = max(0, minX - padding)
        minY = max(0, minY - padding)
        maxX = min(width - 1, maxX + padding)
        maxY = min(height - 1, maxY + padding)

        let cropRect = CGRect(
            x: minX,
            y: minY,
            width: maxX - minX,
            height: maxY - minY
        )

        guard cropRect.width > 0, cropRect.height > 0,
              let croppedCGImage = cgImage.cropping(to: cropRect) else {
            return image
        }

        return UIImage(cgImage: croppedCGImage, scale: image.scale, orientation: image.imageOrientation)
    }
}

// MARK: - Signature Canvas (PencilKit Wrapper)

struct SignatureCanvas: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView

    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        canvasView.drawingPolicy = .anyInput
        canvasView.tool = PKInkingTool(.pen, color: .black, width: 3)
        canvasView.delegate = context.coordinator
        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: SignatureCanvas

        init(_ parent: SignatureCanvas) {
            self.parent = parent
        }
    }
}

// MARK: - Signature Preview View

struct SignaturePreviewView: View {
    let signatureData: Data?
    var onTap: (() -> Void)?

    var body: some View {
        Group {
            if let data = signatureData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 60)
                    .padding(8)
                    .background(Color.white)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            } else {
                HStack {
                    Image(systemName: "signature")
                        .foregroundColor(.secondary)
                    Text("Tap to add signature")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(height: 60)
                .frame(maxWidth: .infinity)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
                        .foregroundColor(.gray.opacity(0.5))
                )
            }
        }
        .onTapGesture {
            onTap?()
        }
    }
}

// MARK: - Signature Settings View

struct SignatureSettingsView: View {
    @State private var signatureData: Data?
    @State private var showingSignatureCapture = false
    @State private var showIncludeOnInvoices: Bool = true

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Your Signature")
                        .font(.headline)

                    SignaturePreviewView(signatureData: signatureData) {
                        showingSignatureCapture = true
                    }

                    if signatureData != nil {
                        HStack {
                            Button(action: { showingSignatureCapture = true }) {
                                Label("Change", systemImage: "pencil")
                                    .font(.subheadline)
                            }

                            Spacer()

                            Button(role: .destructive, action: deleteSignature) {
                                Label("Delete", systemImage: "trash")
                                    .font(.subheadline)
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
            } footer: {
                Text("Your signature will appear on invoices you send to clients.")
            }

            Section {
                Toggle("Include on Invoices", isOn: $showIncludeOnInvoices)
                    .onChange(of: showIncludeOnInvoices) { newValue in
                        var businessInfo = InvoiceStorage.loadBusinessInfo()
                        businessInfo.includeSignatureOnInvoices = newValue
                        InvoiceStorage.saveBusinessInfo(businessInfo)
                    }
            } footer: {
                Text("When enabled, your signature will automatically appear on all generated invoice PDFs.")
            }

            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Label("About Signatures", systemImage: "info.circle.fill")
                        .font(.headline)
                        .foregroundColor(.blue)

                    VStack(alignment: .leading, spacing: 8) {
                        bulletPoint("Signatures add a professional touch to invoices")
                        bulletPoint("Your signature is stored securely on your device")
                        bulletPoint("Use Apple Pencil for best results on iPad")
                        bulletPoint("Signatures sync across your devices with iCloud")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Signature")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadSettings()
        }
        .sheet(isPresented: $showingSignatureCapture) {
            SignatureCaptureView(signatureData: $signatureData)
        }
        .onChange(of: signatureData) { _ in
            saveSignature()
        }
    }

    private func loadSettings() {
        let businessInfo = InvoiceStorage.loadBusinessInfo()
        signatureData = businessInfo.signatureData
        showIncludeOnInvoices = businessInfo.includeSignatureOnInvoices
    }

    @ViewBuilder
    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
            Text(text)
        }
    }

    private func saveSignature() {
        var businessInfo = InvoiceStorage.loadBusinessInfo()
        businessInfo.signatureData = signatureData
        InvoiceStorage.saveBusinessInfo(businessInfo)
    }

    private func deleteSignature() {
        signatureData = nil
        saveSignature()
    }
}

#Preview {
    NavigationStack {
        SignatureSettingsView()
    }
}
