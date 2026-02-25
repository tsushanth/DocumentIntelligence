import SwiftUI
import PencilKit

// MARK: - Invoice Signature Capture View

struct InvoiceSignatureCaptureView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var signatureData: Data?
    @State private var canvasView = PKCanvasView()
    @State private var showingClearConfirmation = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
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

                InvoiceSignatureCanvas(canvasView: $canvasView)
                    .background(Color.white)

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
            .confirmationDialog("Clear Signature?", isPresented: $showingClearConfirmation) {
                Button("Clear", role: .destructive) {
                    canvasView.drawing = PKDrawing()
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private func saveSignature() {
        let image = canvasView.drawing.image(
            from: canvasView.bounds,
            scale: UIScreen.main.scale
        )
        if let pngData = image.pngData() {
            signatureData = pngData
        }
        dismiss()
    }
}

struct InvoiceSignatureCanvas: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView

    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        canvasView.drawingPolicy = .anyInput
        canvasView.tool = PKInkingTool(.pen, color: .black, width: 3)
        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {}
}

struct InvoiceSignaturePreviewView: View {
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
        .onTapGesture { onTap?() }
    }
}

struct InvoiceSignatureSettingsView: View {
    @State private var signatureData: Data?
    @State private var showingSignatureCapture = false
    @State private var showIncludeOnInvoices: Bool = true

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Your Signature")
                        .font(.headline)

                    InvoiceSignaturePreviewView(signatureData: signatureData) {
                        showingSignatureCapture = true
                    }

                    if signatureData != nil {
                        HStack {
                            Button(action: { showingSignatureCapture = true }) {
                                Label("Change", systemImage: "pencil")
                                    .font(.subheadline)
                            }
                            Spacer()
                            Button(role: .destructive, action: { signatureData = nil; saveSignature() }) {
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
            }
        }
        .navigationTitle("Signature")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            let businessInfo = InvoiceStorage.loadBusinessInfo()
            signatureData = businessInfo.signatureData
            showIncludeOnInvoices = businessInfo.includeSignatureOnInvoices
        }
        .sheet(isPresented: $showingSignatureCapture) {
            InvoiceSignatureCaptureView(signatureData: $signatureData)
        }
        .onChange(of: signatureData) { _ in saveSignature() }
    }

    private func saveSignature() {
        var businessInfo = InvoiceStorage.loadBusinessInfo()
        businessInfo.signatureData = signatureData
        InvoiceStorage.saveBusinessInfo(businessInfo)
    }
}

#Preview {
    NavigationStack {
        InvoiceSignatureSettingsView()
    }
}
