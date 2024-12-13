//  Created by Andrew Podkovyrin
//  Copyright © 2020 Andrew Podkovyrin. All rights reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  https://opensource.org/licenses/MIT
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import UIKit

extension UIImage {
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
    
    func resize(to newSize: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        self.draw(in: CGRect(origin: .zero, size: newSize))
        guard let newImage = UIGraphicsGetImageFromCurrentImageContext() else { return UIImage() }
        return newImage
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
