import UIKit
import CoreImage

/// Processes and enhances images with filters
public final class ImageProcessor {

    public enum FilterType {
        case blackAndWhite
        case color
        case grayscale
        case enhanceContrast
        case sharpen
    }

    public init() {}

    /// Apply a filter to an image
    public func applyFilter(_ filter: FilterType, to image: UIImage) -> UIImage? {
        guard let ciImage = CIImage(image: image) else { return nil }

        let filteredImage: CIImage?

        switch filter {
        case .blackAndWhite:
            filteredImage = applyBlackAndWhiteFilter(to: ciImage)

        case .color:
            filteredImage = applyColorFilter(to: ciImage)

        case .grayscale:
            filteredImage = applyGrayscaleFilter(to: ciImage)

        case .enhanceContrast:
            filteredImage = applyContrastEnhancement(to: ciImage)

        case .sharpen:
            filteredImage = applySharpenFilter(to: ciImage)
        }

        guard let outputImage = filteredImage else { return nil }

        let context = CIContext()
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else { return nil }

        return UIImage(cgImage: cgImage)
    }

    // MARK: - Filter Implementations

    private func applyBlackAndWhiteFilter(to image: CIImage) -> CIImage? {
        let filter = CIFilter(name: "CIPhotoEffectNoir")
        filter?.setValue(image, forKey: kCIInputImageKey)

        guard let output = filter?.outputImage else { return nil }

        let contrastFilter = CIFilter(name: "CIColorControls")
        contrastFilter?.setValue(output, forKey: kCIInputImageKey)
        contrastFilter?.setValue(1.5, forKey: kCIInputContrastKey)
        contrastFilter?.setValue(0.0, forKey: kCIInputSaturationKey)

        return contrastFilter?.outputImage
    }

    private func applyColorFilter(to image: CIImage) -> CIImage? {
        let filter = CIFilter(name: "CIColorControls")
        filter?.setValue(image, forKey: kCIInputImageKey)
        filter?.setValue(1.2, forKey: kCIInputContrastKey)
        filter?.setValue(1.1, forKey: kCIInputSaturationKey)
        filter?.setValue(0.0, forKey: kCIInputBrightnessKey)

        return filter?.outputImage
    }

    private func applyGrayscaleFilter(to image: CIImage) -> CIImage? {
        let filter = CIFilter(name: "CIColorControls")
        filter?.setValue(image, forKey: kCIInputImageKey)
        filter?.setValue(0.0, forKey: kCIInputSaturationKey)

        return filter?.outputImage
    }

    private func applyContrastEnhancement(to image: CIImage) -> CIImage? {
        let filter = CIFilter(name: "CIColorControls")
        filter?.setValue(image, forKey: kCIInputImageKey)
        filter?.setValue(1.5, forKey: kCIInputContrastKey)

        return filter?.outputImage
    }

    private func applySharpenFilter(to image: CIImage) -> CIImage? {
        let filter = CIFilter(name: "CISharpenLuminance")
        filter?.setValue(image, forKey: kCIInputImageKey)
        filter?.setValue(0.8, forKey: kCIInputSharpnessKey)

        return filter?.outputImage
    }

    /// Crop image to specified rectangle
    public func crop(_ image: UIImage, to rect: CGRect) -> UIImage? {
        guard let cgImage = image.cgImage?.cropping(to: rect) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    /// Resize image to fit within max dimensions
    public func resize(_ image: UIImage, maxDimension: CGFloat) -> UIImage? {
        let size = image.size
        let ratio = min(maxDimension / size.width, maxDimension / size.height)

        if ratio >= 1 { return image }

        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)

        UIGraphicsBeginImageContextWithOptions(newSize, false, image.scale)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return resizedImage
    }

    /// Compress image data for storage
    public func compress(_ image: UIImage, quality: CGFloat = 0.8) -> Data? {
        return image.jpegData(compressionQuality: quality)
    }
}
