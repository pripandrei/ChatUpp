//
//  TopCropViewControllerRepresentable.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 1/7/25.
//

import SwiftUI
import CropViewController

struct CropViewControllerRepresentable: UIViewControllerRepresentable
{
    private let image: UIImage
    
    init(image: UIImage) {
        self.image = image
    }
    
    func makeUIViewController(context: Context) -> some UIViewController
    {        
        let cropViewController = CropViewController(image: image)
        cropViewController.view.backgroundColor = .blue
        return cropViewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context)
    {
        
    }
}
