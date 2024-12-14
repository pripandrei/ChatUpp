import UIKit
import Kingfisher

//protocol Resizable
//{
//    var size: CGSize {get}
//}
//
//struct ImageSample
//{
//    enum User: Resizable
//    {
//        case original
//        case thumbnail
//        
//        var size: CGSize {
//            switch self {
//            case .original: return CGSize(width: 1024, height: 1024)
//            case .thumbnail: return CGSize(width: 320, height: 320)
//            }
//        }
//    }
//    
//    enum Message: Resizable
//    {
//        case original
//        case thumbnail
//        
//        var size: CGSize {
//            switch self {
//            case .original: return CGSize(width: 1280, height: 1280)
//            case .thumbnail: return CGSize(width: 540, height: 540)
//            }
//        }
//    }
//}


enum ImageSize
{
    enum User {
        static let original = CGSize(width: 1280, height: 1280)
        static let thumbnail = CGSize(width: 320, height: 320)
    }
    
    enum Message {
        static let original = CGSize(width: 1280, height: 1280)
        static let thumbnail = CGSize(width: 540, height: 540)
    }
}

extension UIImage
{
    func resize(_ size: CGSize) -> UIImage
    {
        let resizedImage = self.kf.resize(to: size, for: .aspectFit)
        return resizedImage
    }
    
    func resize(to newSize: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        self.draw(in: CGRect(origin: .zero, size: newSize))
        guard let newImage = UIGraphicsGetImageFromCurrentImageContext() else { return UIImage() }
        return newImage
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
