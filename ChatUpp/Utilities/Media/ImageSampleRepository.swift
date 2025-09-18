//
//  Untitled.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 12/19/24.
//

import UIKit

//MARK: - resizes and stores samples of users/groups/messages images

struct ImageSampleRepository
{
    private let uuidString = UUID().uuidString
    private(set) var samples: [ImageSample.SizeKey: Data] = [:]

    init(image: UIImage, type: ImageSample)
    {
        self.createImageSamples(from: image, for: type)
    }
    
    func imagePath(for size: ImageSample.SizeKey) -> String
    {
        switch size {
        case .original:
            return "\(uuidString).jpg"
        case .medium, .small:
            return "\(uuidString)_\(size.rawValue).jpg"
        }
    }

    mutating private func createImageSamples(from image: UIImage, for type: ImageSample)
    {
        let sortedSizes = type.sizeMapping.values.sorted { $0.width > $1.width }
        
        for (index, size) in sortedSizes.enumerated()
        {
            let imageSample = image.downsample(toSize: size, withCompressionQuality: 0.6).getJpegData()
            let sizeType = ImageSample.SizeKey.allCases[index]
            self.samples[sizeType] = imageSample
        }
    }
}
