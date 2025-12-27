//
//  ThemeGridItem.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 12/2/25.
//
import SwiftUI

struct ThemeGridItemView: View
{
    @StateObject var viewModel: ThemeGridItemViewModel

    var body: some View
    {
        if let imageData = viewModel.imageData,
           let image = UIImage(data: imageData)
        {
            Image(uiImage: image)
                .resizable()
//                .scaledToFill()
                .frame(width: 110, height: 170)
                .clipShape(.rect(cornerRadius: 10))
        }
        else {
            PlaceholderView()
        }
    }
    
    private func PlaceholderView() -> some View
    {
        RoundedRectangle(cornerRadius: 10)
            .fill(.gray)
            .frame(width: 110, height: 170)
            .overlay {
                ProgressView()
            }
    }
}

