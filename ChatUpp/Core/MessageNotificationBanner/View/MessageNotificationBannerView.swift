//
//  MessageNotificationView.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 8/17/25.
//

import SwiftUI

struct MessageNotificationBannerView: View
{
    @ObservedObject var viewModel: MessageNotificationBannerViewModel
    
    var body: some View
    {
        HStack(spacing: 0)
        {
            let avatarImage = viewModel.messageBannerData.avatar
                .flatMap { UIImage(data: $0) } ?? UIImage(named: "default_profile_photo")!
            
            Image(uiImage: avatarImage)
                .resizable()
                .frame(width: 60, height: 60)
                .clipShape(Circle())
            
            VStack(alignment: .leading)
            {
                Text(viewModel.messageBannerData.titleName)
                    .font(.system(size: 18,
                                  weight: .semibold))
                    .foregroundStyle(Color.white)
                    .lineLimit(1)
                
//                Text(viewModel.messageBannerData.message.messageBody)
                Text(viewModel.messageText)
                    .font(.system(size: 16,
                                  weight: .medium))
                    .foregroundStyle(Color.white)
                    .lineLimit(2)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 0)
            
            Spacer()
            
            if let contentImage = viewModel.messageBannerData.contentThumbnail
                .flatMap({ UIImage(data: $0) })
//                ?? UIImage(named: "default_profile_photo")!
            {
                Image(uiImage: contentImage)
                    .resizable()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .frame(
            width: UIScreen.main.bounds.width - 40,
            height: 60,
            alignment: .leading)
        .padding(.all, 10)
        .background(Color(ColorManager.navigationBarBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .shadow(color: .black, radius: 1, x: 0, y: 0)
        .onTapGesture {
            self.viewModel.onTap?()
        }
    }
}

#Preview {
    let chat = Chat()
    let message = Message(id: "", messageBody: "test", senderId: "", timestamp: .now, messageSeen: false, seenBy: [], isEdited: false, imagePath: nil, imageSize: nil, repliedTo: nil, type: .image, sticker: "nil")
    
    let imageData = UIImage(named: "testPath")?.pngData()
    
    let data = MessageBannerData(chat: chat, message: message, avatar: nil, titleName: "Avatar Aang plus catara", contentThumbnail: imageData)
    let viewModel = MessageNotificationBannerViewModel(messageBannerData: data)
    MessageNotificationBannerView(viewModel: viewModel)
}
