import SwiftUI
import Speech

struct VoiceToInvoiceView: View {

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = VoiceToInvoiceViewModel()
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                // Microphone indicator
                ZStack {
                    Circle()
                        .fill(viewModel.isRecording ? Color.red.opacity(0.2) : Color.blue.opacity(0.1))
                        .frame(width: 200, height: 200)
                        .scaleEffect(viewModel.isRecording ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: viewModel.isRecording)

                    Circle()
                        .fill(viewModel.isRecording ? Color.red : Color.blue)
                        .frame(width: 120, height: 120)

                    Image(systemName: viewModel.isRecording ? "waveform" : "mic.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                }

                Text(viewModel.isRecording ? "Listening..." : "Tap to speak")
                    .font(.headline)
                    .foregroundColor(.secondary)

                // Transcript
                if !viewModel.transcript.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("You said:")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(viewModel.transcript)
                            .font(.body)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }

                // Extracted invoice data
                if let invoice = viewModel.extractedInvoice {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Extracted Invoice:")
                            .font(.headline)

                        extractedField("Client", invoice.clientName)
                        extractedField("Description", invoice.description)
                        extractedField("Amount", invoice.formattedAmount)
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }

                Spacer()

                // Record button
                Button(action: {
                    if viewModel.isRecording {
                        viewModel.stopRecording()
                    } else {
                        viewModel.startRecording()
                    }
                }) {
                    Text(viewModel.isRecording ? "Stop" : "Start Recording")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.isRecording ? Color.red : Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal)

                if viewModel.extractedInvoice != nil {
                    Button(action: {
                        viewModel.createInvoice()
                        dismiss()
                    }) {
                        Text("Create Invoice")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }

                Spacer(minLength: 20)
            }
            .navigationTitle("Voice to Invoice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func extractedField(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

struct ExtractedInvoiceData {
    var clientName: String
    var description: String
    var amount: Double

    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}

#Preview {
    VoiceToInvoiceView()
        .environmentObject(AppState())
}
