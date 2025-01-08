//
//  TopCropViewControllerRepresentable.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 1/7/25.
//

import SwiftUI
import PhotosUI
import CropViewController

struct CropViewControllerRepresentable: UIViewControllerRepresentable
{
    private let imageData: Data
    @ObservedObject private var viewModel: GroupCreationViewModel
    
    init(imageData: Data, viewModel: GroupCreationViewModel)
    {
        self.imageData = imageData
        self.viewModel = viewModel
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
        return Coordinator(viewModel: viewModel)
    }
}

//MARK: - Coordinator/delegate class

extension CropViewControllerRepresentable
{
    class Coordinator: NSObject, CropViewControllerDelegate
    {
        @ObservedObject var viewModel: GroupCreationViewModel
        
        init(viewModel: GroupCreationViewModel) {
            self.viewModel = viewModel
        }
        
        func cropViewController(_ cropViewController: CropViewController,
                                didCropToImage image: UIImage,
                                withRect cropRect: CGRect,
                                angle: Int)
        {
            viewModel.imageRepository = ImageSampleRepository(image: image, type: .user)
            cropViewController.dismiss(animated: true)
        }
    }
}
