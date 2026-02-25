import SwiftUI

struct PDFToolsView: View {

    @State private var showingMerge = false
    @State private var showingSplit = false
    @State private var showingCompress = false
    @State private var showingConvert = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    toolCard(
                        title: "Merge PDFs",
                        icon: "doc.on.doc.fill",
                        color: .blue,
                        description: "Combine multiple PDFs"
                    ) {
                        showingMerge = true
                    }

                    toolCard(
                        title: "Split PDF",
                        icon: "scissors",
                        color: .orange,
                        description: "Extract pages"
                    ) {
                        showingSplit = true
                    }

                    toolCard(
                        title: "Compress",
                        icon: "arrow.down.doc.fill",
                        color: .green,
                        description: "Reduce file size"
                    ) {
                        showingCompress = true
                    }

                    toolCard(
                        title: "Convert",
                        icon: "arrow.triangle.2.circlepath",
                        color: .purple,
                        description: "PDF to images"
                    ) {
                        showingConvert = true
                    }

                    toolCard(
                        title: "Password",
                        icon: "lock.fill",
                        color: .red,
                        description: "Protect PDF",
                        isPro: true
                    ) {}

                    toolCard(
                        title: "OCR",
                        icon: "doc.text.viewfinder",
                        color: .indigo,
                        description: "Extract text",
                        isPro: true
                    ) {}
                }
                .padding()
            }
            .navigationTitle("PDF Tools")
        }
    }

    private func toolCard(
        title: String,
        icon: String,
        color: Color,
        description: String,
        isPro: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: icon)
                        .font(.system(size: 40))
                        .foregroundColor(color)

                    if isPro {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                            .offset(x: 10, y: -5)
                    }
                }

                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(color.opacity(0.1))
            .cornerRadius(16)
        }
    }
}

#Preview {
    PDFToolsView()
}
