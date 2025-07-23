import UIKit
import Kingfisher

enum ImageSample
{
    case user, message
    
    enum SizeKey: String, CaseIterable
    {
        /// See FootNote.swift [10]
        case original
        case small
        case medium
    }

    var sizeMapping: [SizeKey: CGSize]
    {
        switch self {
        case .user:
            return [
                .original: CGSize(width: 720, height: 720),
                .medium: CGSize(width: 200, height: 200),
                .small: CGSize(width: 100, height: 100)
            ]
        case .message:
            return [
                .original: CGSize(width: 680, height: 680),
//                .medium: CGSize(width: 200, height: 200),
                .small: CGSize(width: 80, height: 80)
            ]
        }
    }
}

extension UIImage
{
    public func resize(_ size: CGSize) -> UIImage
    {
        let resizedImage = self.kf.resize(to: size, for: .aspectFit)
        return resizedImage
    }
    
    public func compressImage(to quality: CGFloat) -> UIImage?
    {
        guard let data = self.jpegData(compressionQuality: quality) else {return nil}
        return UIImage(data: data)
    }
    
    public func downsample(toSize size: CGSize,
                           withCompressionQuality qulity: CGFloat) -> UIImage
    {
        let resizedImage = self.resize(size)
        guard let compressedImage = resizedImage.compressImage(to: qulity) else {return resizedImage}
        return compressedImage
    }
    
    public func getJpegData() -> Data? {
        return self.jpegData(compressionQuality: 1.0)
    }
    
    func resizeImage(toSize size: CGSize) -> UIImage
    {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
//    
//    func resize(to newSize: CGSize) -> UIImage {
//        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
//        defer { UIGraphicsEndImageContext() }
//        self.draw(in: CGRect(origin: .zero, size: newSize))
//        guard let newImage = UIGraphicsGetImageFromCurrentImageContext() else { return UIImage() }
//        return newImage
//    }
//    
//    func resized5(to newSize: CGSize) -> UIImage? {
//        let format = UIGraphicsImageRendererFormat()
//        format.scale = UIScreen.main.scale
//        format.opaque = false
//
//        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
//        return renderer.image { _ in
//            self.draw(in: CGRect(origin: .zero, size: newSize))
//        }
//    }
//    
    func resize(to newSize: CGSize,
                           scale: CGFloat = UIScreen.main.scale) -> UIImage?
    {
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = false
        
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    
    func roundedCornerImage(with radius: CGFloat) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        
        return renderer.image { rendererContext in
            let rect = CGRect(origin: .zero, size: size)
            let path = UIBezierPath(roundedRect: rect,
                                    byRoundingCorners: .allCorners,
                                    cornerRadii: CGSize(width: radius, height: radius))
            path.close()
            let cgContext = rendererContext.cgContext
            cgContext.saveGState()
            path.addClip()
            draw(in: rect)
            cgContext.restoreGState()
        }
    }

    func getAspectRatio() -> CGSize {
        let (equalWidth, equalHeight) = (250,250)
        
        let preferredWidth: Double = 300
        let preferredHeight: Double = 350
        
        let aspectRatioForWidth = Double(self.size.width) / Double(self.size.height)
        let aspectRatioForHeight = Double(self.size.height) / Double(self.size.width)
        
        if self.size.width > self.size.height {
            let newHeight = preferredWidth / aspectRatioForWidth
            return CGSize(width: preferredWidth, height: newHeight)
        } else if self.size.height > self.size.width {
            let newWidth = preferredHeight / aspectRatioForHeight
            return CGSize(width: newWidth, height: preferredHeight)
        } else {
            return CGSize(width: equalWidth, height: equalHeight)
        }
    }
    
//    func calculateImageMemorySize(image: UIImage) -> Int?
//    {
//        guard let cgImage = image.cgImage else {
//            print("Failed to get CGImage from UIImage")
//            return nil
//        }
//        
//        let width = cgImage.width
//        let height = cgImage.height
//        let bitsPerPixel = cgImage.bitsPerPixel // Typically 32 for RGBA
//        let bytesPerPixel = bitsPerPixel / 8 // 4 bytes for RGBA
//        
//        let memorySizeInBytes = width * height * bytesPerPixel
//        return memorySizeInBytes
//    }
//
//    // Convert bytes to a human-readable format (e.g., KB, MB)
//    func formatMemorySize(bytes: Int) -> String
//    {
//        let formatter = ByteCountFormatter()
//        formatter.countStyle = .memory
//        return formatter.string(fromByteCount: Int64(bytes))
//    }
}

