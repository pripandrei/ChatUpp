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
