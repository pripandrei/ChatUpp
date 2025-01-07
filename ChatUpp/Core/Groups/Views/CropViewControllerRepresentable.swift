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
    @Binding var cropedImage: UIImage?
    private let imageData: Data
    
    
    init(imageData: Data, cropedImage: Binding<UIImage?>)
    {
        self.imageData = imageData
        self._cropedImage = cropedImage
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
        return Coordinator(cropedImage: $cropedImage)
    }
}

//MARK: - Coordinator/delegate class

extension CropViewControllerRepresentable
{
    class Coordinator: NSObject, CropViewControllerDelegate
    {
        @Binding var cropedImage: UIImage?
        
        init(cropedImage: Binding<UIImage?>) {
            self._cropedImage = cropedImage
        }
        
        func cropViewController(_ cropViewController: CropViewController, didCropToImage image: UIImage, withRect cropRect: CGRect, angle: Int)
        {
            self.cropedImage = image
            cropViewController.dismiss(animated: true)
        }
    }
    
}

//MARK: - Helper functions
//extension CropViewControllerRepresentable
//{
//    private func extractImageFromPickerItem() async -> UIImage
//    {
//        if let data = try? await pickerItem.loadTransferable(type: Data.self),
//           let image = UIImage(data: data)
//        {
//            return image
//        }
//    }
//}
