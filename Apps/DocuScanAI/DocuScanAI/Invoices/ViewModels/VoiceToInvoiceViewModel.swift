import SwiftUI
import Speech
import AVFoundation

@MainActor
class VoiceToInvoiceViewModel: ObservableObject {

    @Published var isRecording = false
    @Published var transcript = ""
    @Published var extractedInvoice: ExtractedInvoiceData?
    @Published var errorMessage: String?

    private var audioEngine: AVAudioEngine?
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    init() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        requestPermissions()
    }

    private func requestPermissions() {
        SFSpeechRecognizer.requestAuthorization { _ in }
        AVAudioSession.sharedInstance().requestRecordPermission { _ in }
    }

    func startRecording() {
        isRecording = true
        transcript = ""
        extractedInvoice = nil
    }

    func stopRecording() {
        isRecording = false
        processTranscript()
    }

    private func processTranscript() {
        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            transcript = "Create invoice for John Smith, plumbing repair $120"
            extractedInvoice = ExtractedInvoiceData(
                clientName: "John Smith",
                description: "Plumbing repair",
                amount: 120.00
            )
        }
    }

    func createInvoice() {
        // Will integrate with storage
    }
}
