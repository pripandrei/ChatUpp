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
//    var onTap: (() -> Void)?
    
    var body: some View
    {
            HStack(spacing: 0)
            {
                let image = (viewModel.messageBannerData.avatar)
                    .flatMap { UIImage(data: $0) } ?? UIImage(named: "default_profile_photo")!
                
                Image(uiImage: image)
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
                    
                    Text(viewModel.messageBannerData.message.messageBody)
                        .font(.system(size: 16,
                                      weight: .medium))
                        .foregroundStyle(Color.white)
                        .lineLimit(2)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 0)
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

final class MessageNotificationBannerViewModel: SwiftUI.ObservableObject
{
    let messageBannerData: MessageBannerData
    
    init(messageBannerData: MessageBannerData)
    {
        self.messageBannerData = messageBannerData
    }
    
    var onTap: (() -> Void)?
    

//    private(set) var chat: Chat
//    private(set) var message: Message
//    
//    init(chat: Chat, message: Message)
//    {
//        self.chat = chat
//        self.message = message
//    }
//    
//    var messageSender: User?
//    {
//        let user = RealmDataBase.shared.retrieveSingleObject(
//            ofType: User.self,
//            primaryKey: message.senderId)
//        return user
//    }
//    
//    var messageSenderName: String?
//    {
//        return messageSender?.name
//    }
    
    
    
//    init() {
//        
//    }
}

#Preview {
    let chat = Chat()
    let message = Message()
    let data = MessageBannerData(chat: chat, message: message, avatar: nil, titleName: "Avatar Aang")
    let viewModel = MessageNotificationBannerViewModel(messageBannerData: data)
    MessageNotificationBannerView(viewModel: viewModel)
}
