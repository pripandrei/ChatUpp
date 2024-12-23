//
//  ImageCropper.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 12/23/24.
//

import UIKit
import CropViewController

public final class ImageCropper: NSObject
{
    private let image: UIImage
    @Published public var croppedImage: UIImage?
    
    init(image: UIImage) {
        self.image = image
    }
    
    func presentCropViewController(from viewController: UIViewController)
    {
        let cropVC = CropViewController(croppingStyle: .circular, image: self.image)
        cropVC.delegate = self
        cropVC.aspectRatioLockEnabled = true
        cropVC.resetAspectRatioEnabled = false
        cropVC.toolbar.clampButtonHidden = true
        
        viewController.present(cropVC, animated: true)
    }
}

extension ImageCropper: CropViewControllerDelegate
{
    public func cropViewController(_ cropViewController: CropViewController,
                            didCropToImage image: UIImage,
                            withRect cropRect: CGRect,
                            angle: Int)
    {
        print("Image: ", image)
        croppedImage = image
        cropViewController.dismiss(animated: true)
    }
}
