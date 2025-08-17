//
//  MessageNotificationView.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 8/17/25.
//

import SwiftUI

struct MessageNotificationView: View
{
    @ObservedObject var viewModel: MessageNotificationViewModel
    
    var body: some View
    {
        GeometryReader { geometry in
            HStack(spacing: 0)
            {
                Image("default_profile_photo")
                    .resizable()
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
                
                VStack(alignment: .leading)
                {
                    Text("Eliza")
                        .font(.system(size: 18,
                                      weight: .semibold))
                        .foregroundStyle(Color.white)
                        .lineLimit(1)
                    
                    Text("My dear, you are doing it right as it should be from yuor side")
                        .font(.system(size: 16,
                                      weight: .medium))
                        .foregroundStyle(Color.white)
                        .lineLimit(2)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 0)
            }
            .frame(width: geometry.size.width - 70,
                   height: 60,
                   alignment: .leading)
            .padding(.all, 10)
            .background(Color(ColorManager.navigationBarBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .position(x: geometry.size.width / 2,
                      y: geometry.size.height / 2)
        }
    }
}

final class MessageNotificationViewModel: SwiftUI.ObservableObject
{
    
}

#Preview {
    let viewModel = MessageNotificationViewModel()
    MessageNotificationView(viewModel: viewModel)
}
