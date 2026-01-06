//
//  MessageComponents.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 9/18/25.
//

import UIKit
import YYText


enum ComponentsContext {
    case incoming
    case outgoing
}

final class MessageComponentsView: UIView
{
    private var viewModel: MessageComponentsViewModel!
    private(set) var messageComponentsStackView: UIStackView = UIStackView()
    private var seenStatusMark = YYLabel()
    private var editedLabel: UILabel = UILabel()
    private var timeStamp = YYLabel()
    
    init() {
        super.init(frame: .zero)
        setupMessageComponentsStackView()
        setupTimestamp()
        setupEditedLabel()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupMessageComponentsStackView()
    {
        addSubview(messageComponentsStackView)
        
        messageComponentsStackView.addArrangedSubview(editedLabel)
        messageComponentsStackView.addArrangedSubview(timeStamp)
        messageComponentsStackView.addArrangedSubview(seenStatusMark)
        
        messageComponentsStackView.axis = .horizontal
        messageComponentsStackView.alignment = .center
        messageComponentsStackView.distribution = .equalSpacing
        messageComponentsStackView.spacing = 3
        messageComponentsStackView.clipsToBounds = true
        messageComponentsStackView.translatesAutoresizingMaskIntoConstraints = false
        
        
        NSLayoutConstraint.activate([
            messageComponentsStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            messageComponentsStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            messageComponentsStackView.topAnchor.constraint(equalTo: topAnchor),
            messageComponentsStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
        ])
    }
    
    private func setupEditedLabel()
    {
//        messageComponentsStackView.insertArrangedSubview(editedLabel, at: 0)
        editedLabel.font = UIFont(name: "Helvetica", size: 12)
    }
    
    private func setupTimestamp()
    {
        timeStamp.font = UIFont(name: "HelveticaNeue", size: 12)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateStackViewComponentsAppearance()
    }
    
    private func updateStackViewComponentsAppearance()
    {
        guard let messageType = viewModel?.message.type else {return}

        switch messageType
        {
        case .image, .sticker:
            messageComponentsStackView.backgroundColor = #colorLiteral(red: 0.1982198954, green: 0.2070500851, blue: 0.2227896452, alpha: 1).withAlphaComponent(0.8)
            messageComponentsStackView.isLayoutMarginsRelativeArrangement = true
            messageComponentsStackView.layoutMargins = UIEdgeInsets(top: 2, left: 4, bottom: 2, right: 4)
            messageComponentsStackView.layer.cornerRadius = bounds.height / 2
        case .text, .imageText, .audio :
            messageComponentsStackView.backgroundColor = .clear
            messageComponentsStackView.isLayoutMarginsRelativeArrangement = false
            messageComponentsStackView.layoutMargins = .zero
            messageComponentsStackView.layer.cornerRadius = .zero
        default: break
        }
        updateStackViewComponentsColor()
    }
    
    private func updateStackViewComponentsColor()
    {
        timeStamp.textColor = getColorForMessageComponents()
        editedLabel.textColor = getColorForMessageComponents()
    }
    
    func updateEditedLabel()
    {
        if viewModel.message.isEdited == true
        {
            editedLabel.text = "edited"
        }
    }
    
    func configureMessageSeenStatus()
    {
        guard viewModel.componentsContext == .outgoing else {return}
        
        let isSeen = viewModel.isMessageSeen
        let iconSize = isSeen ? CGSize(width: 14, height: 10) : CGSize(width: 10, height: 10)
        
        let seenIconColor: UIColor = getColorForMessageComponents()
        let seenStatusIcon = isSeen ? SeenStatusIcon.double.rawValue : SeenStatusIcon.single.rawValue
        
        guard let seenStatusIconImage = SeenStatusIconStorage.image(named: seenStatusIcon,
                                                                    size: iconSize,
                                                                    color: seenIconColor)
        else {return}
        
        let imageAttributedString = NSMutableAttributedString.yy_attachmentString(
            withContent: seenStatusIconImage,
            contentMode: .center,
            attachmentSize: seenStatusIconImage.size,
            alignTo: UIFont(name: "Helvetica", size: 14)!,
            alignment: .center)
        
        seenStatusMark.attributedText = imageAttributedString
    }
    
    private func getColorForMessageComponents() -> UIColor
    {
        var color: UIColor = ColorScheme.outgoingMessageComponentsTextColor
        
        if viewModel.message.type == .image || viewModel.message.type == .sticker
        {
            color = .white
        } else {
            color = viewModel.componentsContext == .incoming ? ColorScheme.incomingMessageComponentsTextColor : ColorScheme.outgoingMessageComponentsTextColor
        }
        return color
    }
}

//MARK: - Computed properties
extension MessageComponentsView
{
    var componentsWidth: CGFloat
    {
        let sideWidth = viewModel.componentsContext == .outgoing ? seenStatusMark.intrinsicContentSize.width : 0.0
        return timeStamp.intrinsicContentSize.width + sideWidth + editedMessageWidth + 4.0
    }
    
    private var editedMessageWidth: CGFloat {
        return editedLabel.intrinsicContentSize.width
    }
}

//MARK: cleanup

extension MessageComponentsView
{
    func cleanupContent()
    {
        timeStamp.text = nil
        seenStatusMark.attributedText = nil
        editedLabel.text = nil
    }
}

//MARK: - configuration
extension MessageComponentsView
{
    func configure(viewModel: MessageComponentsViewModel)
    {
        self.viewModel = viewModel
        timeStamp.text = viewModel.timestamp
        updateEditedLabel()
        configureMessageSeenStatus()
//        updateStackViewComponentsAppearance()
    }
}





////
////  ThemeSelectionScreen.swift
////  ChatUpp
////
////  Created by Andrei Pripa on 11/28/25.
////
//
//import SwiftUI
//
//struct ThemesPackScreen: View
//{
//    @StateObject var viewModel: ThemeSelectionScreenViewModel = .init()
//    @State var showThemeSelectionScreenSheet: Bool = false
//    
//    let columns: Array = Array(repeating: GridItem(.flexible(),
//                                                   spacing: -20,
//                                                   alignment: .center),
//                               count: 3)
//    
//    var body: some View
//    {
//        ScrollView()
//        {
//            Text("Themes")
//                .font(Font.system(size: 18, weight: .semibold))
//                .padding([.bottom, .top], 10)
//                .foregroundStyle(.white)
//            
//            LazyVGrid(columns: columns, spacing: 10)
//            {
//                ForEach(0..<20) { item in
//                    
//                    let themeName = viewModel.themes[item % viewModel.themes.count]
//                    
//                    Image(themeName)
//                        .resizable()
////                        .scaledToFit()
//                        .frame(width: 110, height: 170)
//                        .clipShape(.rect(cornerRadius: 10))
//                        .overlay {
//                            if item == viewModel.selectedTheme
//                            {
//                                selectionView()
//                            }
//                        }
//                        .onTapGesture {
//                            viewModel.selectedTheme = item
//                            showThemeSelectionScreenSheet = true
//                        }
//                }
//            }
//        }
//        .background(Color(ColorScheme.appBackgroundColor))
//        .sheet(isPresented: $showThemeSelectionScreenSheet) {
//            showThemeSelectionScreenSheet = false
//        } content: {
//                ThemeSelectionScreen(viewModel: viewModel)
//                    .presentationDetents([.large])
//                    .presentationDragIndicator(.hidden)
//        }
//
//    }
//}
//
//extension ThemesPackScreen
//{
//    private func selectionView() -> some View
//    {
////        Image(systemName: "checkmark.circle.fill")
////            .resizable()
////            .scaledToFit()
////            .frame(width: 50, height: 50)
////            .foregroundStyle(Color(ColorScheme.incomingMessageBackgroundColor))
//////            .background(Color(ColorScheme.incomingMessageBackgroundColor))
////
//        Circle()
//            .frame(width: 45, height: 45)
//            .foregroundStyle(Color(ColorScheme.incomingMessageBackgroundColor))
////            .background(Color(ColorScheme.incomingMessageBackgroundColor))
//            .overlay {
//                Image(systemName: "checkmark")
//                    .resizable()
//                    .scaledToFit()
//                    .frame(width: 18, height: 18)
//                    .foregroundStyle(.white)
//            }
//    }
//}
//
//final class ThemeSelectionScreenViewModel: SwiftUI.ObservableObject
//{
//    let themes = ["chatRoom_background_1",
//                  "chatRoom_background_2",
//                  "chatRoom_background_3"]
//    @Published var selectedTheme = 1
//}
//
//struct ThemeSelectionScreen: View
//{
//    @ObservedObject var viewModel: ThemeSelectionScreenViewModel
//    
//    var body: some View
//    {
//        NavigationStack
//        {
//            VStack
//            {
//                Spacer()
//                
//                ForEach(MessageAligment.allCases) { alignment in
//                    HStack
//                    {
//                        if alignment == .trailing
//                        {
//                            Spacer()
//                        }
//                        
//                        HStack
//                        {
//                            MessageBubble(alignment: alignment)
//                        }
//                        .frame(maxWidth: 250)
//                        
//                        if alignment == .leading
//                        {
//                            Spacer()
//                        }
//                    }
//                }
//                
//                ApplyButton()
//                    .padding(.top, 70)
//            }
//            .toolbar {
//                ToolbarLeadingItem()
//            }
//            .padding(.bottom, 10)
//        }
//    }
//}
//
//extension ThemeSelectionScreen
//{
//    @ToolbarContentBuilder
//    private func ToolbarLeadingItem() -> some ToolbarContent
//    {
//        ToolbarItem(placement: .topBarLeading) {
//            cancelButton()
//        }
//    }
//    
//    private func cancelButton() -> some View
//    {
//        Capsule(style: .circular)
//            .frame(width: 65, height: 25)
//            .foregroundStyle(Color(ColorScheme.footerSectionBackgroundColor.withAlphaComponent(0.8)))
//            .overlay {
//                Text("Cancel")
//                    .font(.system(size: 14, weight: .semibold))
//                    .foregroundStyle(.white)
//            }
//    }
//    
//    private func ApplyButton() -> some View {
//        RoundedRectangle(cornerRadius: 10.0)
//            .frame(height: 45)
//            .frame(maxWidth: .infinity)
//            .foregroundStyle(Color(ColorScheme.footerSectionBackgroundColor))
//            .overlay {
//                Text("Apply For All Chats")
//                    .font(.system(size: 17, weight: .semibold))
//                    .foregroundStyle(.white)
//            }
//            .padding(.horizontal, 20)
//    }
//    
//    private func MessageBubble(alignment: MessageAligment) -> some View
//    {
//        let color = alignment == .trailing ? Color(ColorScheme.outgoingMessageBackgroundColor) :
//            Color(ColorScheme.incomingMessageBackgroundColor)
//        
//        let messageText = alignment == .leading ? "Swipe left or right to preview more wallpapers" : "Set wallpaper for all chats"
//        
//        let paddingBottom = alignment == .leading ? 5.0 : 20.0
//        
//        return Text(messageText)
//            .font(.custom("HelveticaNeue", size: 16))
//            .foregroundStyle(.white)
//            .padding(.horizontal, 10)
//            .padding(.top, 5)
//            .padding(.bottom, paddingBottom)
//            .background {
//                RoundedRectangle(cornerRadius: 15.0)
//                    .foregroundStyle(color)
//            }
////            .frame(maxWidth: 230)
//            .overlay(alignment: .bottomTrailing) {
//                Timestamp()
//                    .padding([.bottom], 4)
//                    .padding(.trailing, 9)
//            }
//    }
//    
//    private func Timestamp() -> some View
//    {
//        Text("20:40")
//            .font(.system(size: 11, weight: .medium))
//            .foregroundStyle(Color(ColorScheme.outgoingMessageComponentsTextColor))
//    }
//}
//
//extension ThemeSelectionScreen
//{
//    enum MessageAligment: Int, Identifiable, CaseIterable
//    {
//        case leading
//        case trailing
//        
//        var id: Int
//        {
//           return rawValue
//        }
//    }
//}
//
