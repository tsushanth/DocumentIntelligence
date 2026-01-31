import UIKit
import Vision

/// OCR text recognition using Vision framework
public final class TextRecognizer {

    public enum RecognitionLevel {
        case fast
        case accurate
    }

    public init() {}

    /// Recognize text in an image
    public func recognizeText(in image: UIImage, level: RecognitionLevel = .accurate) async throws -> RecognizedText {
        guard let cgImage = image.cgImage else {
            throw TextRecognizerError.invalidImage
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: RecognizedText(blocks: [], fullText: ""))
                    return
                }

                let blocks = observations.compactMap { observation -> TextBlock? in
                    guard let candidate = observation.topCandidates(1).first else { return nil }

                    return TextBlock(
                        text: candidate.string,
                        confidence: candidate.confidence,
                        boundingBox: observation.boundingBox
                    )
                }

                let fullText = blocks.map { $0.text }.joined(separator: "\n")

                continuation.resume(returning: RecognizedText(blocks: blocks, fullText: fullText))
            }

            // Configure recognition level
            switch level {
            case .fast:
                request.recognitionLevel = .fast
                request.usesLanguageCorrection = false
            case .accurate:
                request.recognitionLevel = .accurate
                request.usesLanguageCorrection = true
            }

            request.revision = VNRecognizeTextRequestRevision3

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    /// Recognize text in a PDF page
    public func recognizeText(in pdfPage: CGPDFPage, level: RecognitionLevel = .accurate) async throws -> RecognizedText {
        // Convert PDF page to image
        let pageRect = pdfPage.getBoxRect(.mediaBox)
        let renderer = UIGraphicsImageRenderer(size: pageRect.size)

        let image = renderer.image { context in
            context.cgContext.saveGState()
            context.cgContext.translateBy(x: 0, y: pageRect.height)
            context.cgContext.scaleBy(x: 1.0, y: -1.0)
            context.cgContext.drawPDFPage(pdfPage)
            context.cgContext.restoreGState()
        }

        return try await recognizeText(in: image, level: level)
    }

    /// Search for specific text in recognized results
    public func search(for query: String, in recognizedText: RecognizedText, caseSensitive: Bool = false) -> [TextBlock] {
        recognizedText.blocks.filter { block in
            if caseSensitive {
                return block.text.contains(query)
            } else {
                return block.text.lowercased().contains(query.lowercased())
            }
        }
    }
}

/// Errors that can occur during text recognition
public enum TextRecognizerError: LocalizedError {
    case invalidImage
    case recognitionFailed

    public var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "The provided image is invalid or cannot be processed"
        case .recognitionFailed:
            return "Text recognition failed"
        }
    }
}

/// Container for all recognized text
public struct RecognizedText: Codable {
    public let blocks: [TextBlock]
    public let fullText: String

    public init(blocks: [TextBlock], fullText: String) {
        self.blocks = blocks
        self.fullText = fullText
    }

    /// Get text blocks sorted by position (top to bottom, left to right)
    public var sortedBlocks: [TextBlock] {
        blocks.sorted { first, second in
            // Sort by Y position first (top to bottom)
            if abs(first.boundingBox.minY - second.boundingBox.minY) > 0.05 {
                return first.boundingBox.minY > second.boundingBox.minY
            }
            // Then by X position (left to right)
            return first.boundingBox.minX < second.boundingBox.minX
        }
    }

    /// Search for text patterns
    public func matches(pattern: String) -> [String] {
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(fullText.startIndex..., in: fullText)

        let matches = regex?.matches(in: fullText, options: [], range: range) ?? []

        return matches.compactMap { match in
            guard let range = Range(match.range, in: fullText) else { return nil }
            return String(fullText[range])
        }
    }
}
