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
    private var image: UIImage?
    private let imageData: Data
    
    init(imageData: Data)
    {
        self.imageData = imageData
    }
    
    func makeUIViewController(context: Context) -> some UIViewController
    {
        let cropViewController = CropViewController(image: UIImage(data: imageData) ?? UIImage())
        cropViewController.view.backgroundColor = .blue
        return cropViewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context)
    {
        
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
