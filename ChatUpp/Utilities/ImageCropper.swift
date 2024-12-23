//
//  ImageCropper.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 12/23/24.
//

import UIKit
import CropViewController

final class ImageCropper: NSObject
{
    @Published public var croppedImage: UIImage?
    private var image: UIImage
    
    init(image: UIImage) {
        self.image = image
    }
    
    deinit {
        print("ImageCropper was deinit")
    }
    
    func presentCropViewController(from viewController: UIViewController)
    {
        let cropVC = CropViewController(croppingStyle: .circular, image: image)
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
        croppedImage = image
        cropViewController.dismiss(animated: true)
    }
    
    func cropViewController(_ cropViewController: CropViewController, didFinishCancelled cancelled: Bool) {
        croppedImage = nil
        cropViewController.dismiss(animated: true)
    }
}
