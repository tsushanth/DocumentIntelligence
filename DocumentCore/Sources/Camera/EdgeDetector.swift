import UIKit
import Vision

/// Detects document edges in images using Vision framework
public final class EdgeDetector {

    public init() {}

    /// Detect document rectangle in an image
    public func detectDocumentBounds(in image: UIImage) async throws -> CGRect? {
        guard let cgImage = image.cgImage else { return nil }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNDetectRectanglesRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations = request.results as? [VNRectangleObservation],
                      let bestObservation = observations.first else {
                    continuation.resume(returning: nil)
                    return
                }

                // Convert normalized coordinates to image coordinates
                let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
                let boundingBox = self.convertToImageCoordinates(
                    bestObservation.boundingBox,
                    imageSize: imageSize
                )

                continuation.resume(returning: boundingBox)
            }

            // Configure for document detection
            request.minimumAspectRatio = 0.3
            request.maximumAspectRatio = 1.0
            request.minimumSize = 0.1
            request.maximumObservations = 1
            request.minimumConfidence = 0.5

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    /// Detect document corners for perspective correction
    public func detectDocumentCorners(in image: UIImage) async throws -> DocumentCorners? {
        guard let cgImage = image.cgImage else { return nil }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNDetectRectanglesRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations = request.results as? [VNRectangleObservation],
                      let bestObservation = observations.first else {
                    continuation.resume(returning: nil)
                    return
                }

                let imageSize = CGSize(width: cgImage.width, height: cgImage.height)

                let corners = DocumentCorners(
                    topLeft: self.convertPoint(bestObservation.topLeft, imageSize: imageSize),
                    topRight: self.convertPoint(bestObservation.topRight, imageSize: imageSize),
                    bottomLeft: self.convertPoint(bestObservation.bottomLeft, imageSize: imageSize),
                    bottomRight: self.convertPoint(bestObservation.bottomRight, imageSize: imageSize)
                )

                continuation.resume(returning: corners)
            }

            request.minimumAspectRatio = 0.3
            request.maximumAspectRatio = 1.0
            request.minimumSize = 0.1
            request.maximumObservations = 1
            request.minimumConfidence = 0.5

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    /// Apply perspective correction to an image based on detected corners
    public func applyPerspectiveCorrection(to image: UIImage, corners: DocumentCorners) -> UIImage? {
        guard let ciImage = CIImage(image: image) else { return nil }

        guard let filter = CIFilter(name: "CIPerspectiveCorrection") else { return nil }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(CIVector(cgPoint: corners.topLeft), forKey: "inputTopLeft")
        filter.setValue(CIVector(cgPoint: corners.topRight), forKey: "inputTopRight")
        filter.setValue(CIVector(cgPoint: corners.bottomLeft), forKey: "inputBottomLeft")
        filter.setValue(CIVector(cgPoint: corners.bottomRight), forKey: "inputBottomRight")

        guard let outputImage = filter.outputImage else { return nil }

        let context = CIContext()
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else { return nil }

        return UIImage(cgImage: cgImage)
    }

    // MARK: - Private Helpers

    private func convertToImageCoordinates(_ normalizedRect: CGRect, imageSize: CGSize) -> CGRect {
        // Vision uses bottom-left origin, UIKit uses top-left
        let x = normalizedRect.origin.x * imageSize.width
        let y = (1 - normalizedRect.origin.y - normalizedRect.height) * imageSize.height
        let width = normalizedRect.width * imageSize.width
        let height = normalizedRect.height * imageSize.height

        return CGRect(x: x, y: y, width: width, height: height)
    }

    private func convertPoint(_ normalizedPoint: CGPoint, imageSize: CGSize) -> CGPoint {
        // Vision uses bottom-left origin with normalized coordinates
        // CIFilter expects points in image coordinates
        return CGPoint(
            x: normalizedPoint.x * imageSize.width,
            y: normalizedPoint.y * imageSize.height
        )
    }
}

/// Represents the four corners of a detected document
public struct DocumentCorners {
    public let topLeft: CGPoint
    public let topRight: CGPoint
    public let bottomLeft: CGPoint
    public let bottomRight: CGPoint

    public init(topLeft: CGPoint, topRight: CGPoint, bottomLeft: CGPoint, bottomRight: CGPoint) {
        self.topLeft = topLeft
        self.topRight = topRight
        self.bottomLeft = bottomLeft
        self.bottomRight = bottomRight
    }
}
