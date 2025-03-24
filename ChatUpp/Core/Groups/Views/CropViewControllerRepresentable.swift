//
//  TopCropViewControllerRepresentable.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 1/7/25.
//

import SwiftUI
import PhotosUI
import CropViewController

protocol ImageRepositoryRepresentable
{
    func updateImageRepository(repository: ImageSampleRepository)
}

struct CropViewControllerRepresentable: UIViewControllerRepresentable
{
    private let imageData: Data
    private let imageRepositoryRepresentable: ImageRepositoryRepresentable
    
    init(imageData: Data,
         imageRepositoryRepresentable: ImageRepositoryRepresentable)
    {
        self.imageData = imageData
        self.imageRepositoryRepresentable = imageRepositoryRepresentable
    }
    
    func makeUIViewController(context: Context) -> some UIViewController
    {
        let cropViewController = CropViewController(croppingStyle: .circular, image: UIImage(data: imageData) ?? UIImage())
        cropViewController.view.backgroundColor = .blue
        cropViewController.aspectRatioLockEnabled = true
        cropViewController.resetAspectRatioEnabled = false
        cropViewController.toolbar.clampButtonHidden = true
        cropViewController.delegate = context.coordinator
        return cropViewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context)
    {
        /// update SwiftUI code here
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(imageRepository: imageRepositoryRepresentable)
    }
}

//MARK: - Coordinator/delegate class

extension CropViewControllerRepresentable
{
    class Coordinator: NSObject, CropViewControllerDelegate
    {
        private var imageRepositoryRepresentable: ImageRepositoryRepresentable
        
        init(imageRepository: ImageRepositoryRepresentable) {
            self.imageRepositoryRepresentable = imageRepository
        }
        
        func cropViewController(_ cropViewController: CropViewController,
                                didCropToImage image: UIImage,
                                withRect cropRect: CGRect,
                                angle: Int)
        {
            let imageRepository = ImageSampleRepository(image: image, type: .user)
            imageRepositoryRepresentable.updateImageRepository(repository: imageRepository)
            cropViewController.dismiss(animated: true)
        }
    }
}
