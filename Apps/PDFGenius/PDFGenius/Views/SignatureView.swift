import SwiftUI

struct SignatureView: View {
    
    let onSignature: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var lines: [[CGPoint]] = []
    @State private var currentLine: [CGPoint] = []
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Sign below")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                // Signature Canvas
                SignatureCanvas(lines: $lines, currentLine: $currentLine)
                    .frame(height: 200)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .padding(.horizontal)
                
                HStack(spacing: 20) {
                    Button(action: clearSignature) {
                        Text("Clear")
                            .font(.headline)
                            .foregroundColor(.red)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 12)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(10)
                    }
                    
                    Button(action: saveSignature) {
                        Text("Done")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 12)
                            .background(lines.isEmpty ? Color.gray : Color.purple)
                            .cornerRadius(10)
                    }
                    .disabled(lines.isEmpty)
                }
                
                Spacer()
            }
            .padding(.top, 20)
            .navigationTitle("Add Signature")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private func clearSignature() {
        lines.removeAll()
        currentLine.removeAll()
    }
    
    private func saveSignature() {
        // Convert lines to UIImage
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 300, height: 100))
        let image = renderer.image { context in
            context.cgContext.setStrokeColor(UIColor.black.cgColor)
            context.cgContext.setLineWidth(2)
            context.cgContext.setLineCap(.round)
            
            for line in lines {
                guard line.count > 1 else { continue }
                context.cgContext.move(to: line[0])
                for point in line.dropFirst() {
                    context.cgContext.addLine(to: point)
                }
                context.cgContext.strokePath()
            }
        }
        
        onSignature(image)
        dismiss()
    }
}

struct SignatureCanvas: View {
    @Binding var lines: [[CGPoint]]
    @Binding var currentLine: [CGPoint]
    
    var body: some View {
        Canvas { context, size in
            for line in lines {
                drawLine(context: context, line: line)
            }
            drawLine(context: context, line: currentLine)
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    currentLine.append(value.location)
                }
                .onEnded { _ in
                    lines.append(currentLine)
                    currentLine.removeAll()
                }
        )
    }
    
    private func drawLine(context: GraphicsContext, line: [CGPoint]) {
        guard line.count > 1 else { return }
        
        var path = Path()
        path.move(to: line[0])
        for point in line.dropFirst() {
            path.addLine(to: point)
        }
        
        context.stroke(path, with: .color(.black), lineWidth: 2)
    }
}

#Preview {
    SignatureView(onSignature: { _ in })
}
