import SwiftUI
import PDFKit

struct PasswordPDFView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var sourceURL: URL?
    @State private var showingFilePicker = false
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isProtecting = false
    @State private var showingShareSheet = false
    @State private var showingSuccess = false
    @State private var protectedURL: URL?
    @State private var errorMessage: String?

    var passwordsMatch: Bool {
        !password.isEmpty && password == confirmPassword
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if sourceURL == nil {
                    emptyState
                } else {
                    passwordForm
                }
            }
            .padding()
            .navigationTitle("Password Protect")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [.pdf],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        _ = url.startAccessingSecurityScopedResource()
                        sourceURL = url
                    }
                case .failure:
                    errorMessage = "Failed to import file."
                }
            }
            .alert("Error", isPresented: .init(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .alert("Protected Successfully", isPresented: $showingSuccess) {
                Button("Done") { dismiss() }
            } message: {
                Text("Your password-protected PDF has been saved and is available in your documents.")
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "lock.doc.fill")
                .font(.system(size: 60))
                .foregroundStyle(.red.opacity(0.5))
            Text("Password Protect a PDF")
                .font(.title3.bold())
            Text("Add a password to prevent unauthorized access to your document.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Choose PDF") { showingFilePicker = true }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            Spacer()
        }
    }

    private var passwordForm: some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "doc.fill")
                    .foregroundStyle(.red)
                Text(sourceURL?.lastPathComponent ?? "PDF")
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 12) {
                Text("Set Password")
                    .font(.subheadline.bold())

                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)

                SecureField("Confirm Password", text: $confirmPassword)
                    .textFieldStyle(.roundedBorder)

                if !password.isEmpty && !confirmPassword.isEmpty && !passwordsMatch {
                    Text("Passwords don't match")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            Spacer()

            Button {
                protectPDF()
            } label: {
                HStack {
                    if isProtecting {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "lock.fill")
                        Text("Protect PDF")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(passwordsMatch ? Color.red : Color.gray)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(!passwordsMatch || isProtecting)
        }
    }

    private func protectPDF() {
        guard let url = sourceURL, let document = PDFDocument(url: url) else {
            errorMessage = "Failed to load PDF."
            return
        }

        isProtecting = true

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("Protected_\(Date().timeIntervalSince1970).pdf")

        let options: [PDFDocumentWriteOption: Any] = [
            .ownerPasswordOption: password,
            .userPasswordOption: password
        ]

        if document.write(to: tempURL, withOptions: options) {
            // Save to app's Documents/PDFs
            let docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let pdfDir = docsDir.appendingPathComponent("PDFs", isDirectory: true)
            try? FileManager.default.createDirectory(at: pdfDir, withIntermediateDirectories: true)
            let name = url.deletingPathExtension().lastPathComponent
            let savedURL = pdfDir.appendingPathComponent("\(name)_protected.pdf")
            do {
                if FileManager.default.fileExists(atPath: savedURL.path) {
                    try FileManager.default.removeItem(at: savedURL)
                }
                try FileManager.default.copyItem(at: tempURL, to: savedURL)
                protectedURL = savedURL
                url.stopAccessingSecurityScopedResource()
                isProtecting = false
                showingSuccess = true
            } catch {
                errorMessage = "Failed to save: \(error.localizedDescription)"
                url.stopAccessingSecurityScopedResource()
                isProtecting = false
            }
        } else {
            errorMessage = "Failed to protect PDF."
            url.stopAccessingSecurityScopedResource()
            isProtecting = false
        }
    }
}
