//
//  ColorManager.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 2/9/25.
//

import UIKit
import SkeletonView

struct ColorManager
{
//    static let oldMainAppColor: UIColor = #colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 1)
    static let appBackgroundColor: UIColor = #colorLiteral(red: 0.2099263668, green: 0.151156038, blue: 0.2217666507, alpha: 1)
    static let appBackgroundColor2: UIColor = #colorLiteral(red: 0.1236810908, green: 0.08473216742, blue: 0.1324510276, alpha: 1)
    static let navigationBarBackgroundColor: UIColor = #colorLiteral(red: 0.2569749951, green: 0.1936042905, blue: 0.2717022896, alpha: 1)
//    #colorLiteral(red: 0.2135980725, green: 0.1503953636, blue: 0.2242289484, alpha: 1)
    static let navigationSearchFieldBackgroundColor: UIColor = #colorLiteral(red: 0.1695529222, green: 0.1113216504, blue: 0.1723338962, alpha: 1)
    static let tabBarBackgroundColor: UIColor = #colorLiteral(red: 0.2214901745, green: 0.1582537889, blue: 0.2320964336, alpha: 1)
    static let tabBarSelectedItemsTintColor: UIColor = actionButtonsTintColor
    static let tabBarNormalItemsTintColor: UIColor = #colorLiteral(red: 0.5385198593, green: 0.4843533039, blue: 0.5624566674, alpha: 1)
    static let cellSelectionBackgroundColor: UIColor = #colorLiteral(red: 0.1026760712, green: 0.07338444144, blue: 0.1081472859, alpha: 1)
    static let listCellBackgroundColor: UIColor = #colorLiteral(red: 0.2667922974, green: 0.1890299022, blue: 0.2787306905, alpha: 1)
    static let actionButtonsTintColor: UIColor = #colorLiteral(red: 0.8031871915, green: 0.4191343188, blue: 0.9248215556, alpha: 1)
    static let mainAppBackgroundColorGradientTop: UIColor = #colorLiteral(red: 0.468229115, green: 0.2259758115, blue: 0.5086464882, alpha: 1)
    static let mainAppBackgroundColorGradientBottom: UIColor = #colorLiteral(red: 0.468229115, green: 0.2259758115, blue: 0.5086464882, alpha: 1)
    
    static let textFieldPlaceholderColor: UIColor = #colorLiteral(red: 0.5250927806, green: 0.5004045963, blue: 0.5016652346, alpha: 1)
    static let textFieldTextColor: UIColor = .white
    static let messageTextFieldBackgroundColor: UIColor = #colorLiteral(red: 0.1236810908, green: 0.08473216742, blue: 0.1324510276, alpha: 1)
    
    static let inputBarMessageContainerBackgroundColor: UIColor = #colorLiteral(red: 0.2306482196, green: 0.1865905523, blue: 0.2809014618, alpha: 1)
    static let sendMessageButtonBackgroundColor: UIColor = #colorLiteral(red: 0.8080032468, green: 0.4144457579, blue: 0.9248802066, alpha: 1)
    
    static let unseenMessagesBadgeBackgroundColor: UIColor = #colorLiteral(red: 0.8423270583, green: 0.4228419662, blue: 0.9524703622, alpha: 1)
    static let unseenMessagesBadgeTextColor: UIColor = .white
    
    static let incomingMessageBackgroundColor: UIColor = #colorLiteral(red: 0.2260040045, green: 0.1867897213, blue: 0.2767668962, alpha: 1)
    static let outgoingMessageBackgroundColor: UIColor = #colorLiteral(red: 0.5294494033, green: 0.1983171999, blue: 0.5416952372, alpha: 1)
    static let incomingMessageComponentsTextColor: UIColor = #colorLiteral(red: 0.6161918044, green: 0.5466015935, blue: 0.627902925, alpha: 1)
    static let outgoingMessageComponentsTextColor: UIColor = #colorLiteral(red: 0.7367274165, green: 0.5783247948, blue: 0.7441712618, alpha: 1)
    static let messageEventBackgroundColor: UIColor = #colorLiteral(red: 0.2021965683, green: 0.2685731351, blue: 0.3312993646, alpha: 1)
    static let messageSeenStatusIconColor: UIColor = outgoingMessageComponentsTextColor
    static let messageLinkColor: UIColor = #colorLiteral(red: 0, green: 0.6172372699, blue: 0.9823173881, alpha: 1)
    
    static let skeletonItemColor: UIColor = #colorLiteral(red: 0.3543712497, green: 0.2847208381, blue: 0.3677620888, alpha: 1)
    static let skeletonAnimationColor: UIColor = #colorLiteral(red: 0.6587312222, green: 0.6021129489, blue: 0.779224813, alpha: 1)
    
    private static let messageBackgroundColors: [UIColor] = [#colorLiteral(red: 0.8381425738, green: 0.3751247525, blue: 0.5768371224, alpha: 1), #colorLiteral(red: 0.2789569199, green: 0.7063412666, blue: 0.7922309637, alpha: 1), #colorLiteral(red: 0.1472819448, green: 0.5721367598, blue: 0.2217415869, alpha: 1), #colorLiteral(red: 0.7625821829, green: 0.4211770296, blue: 0.1522820294, alpha: 1), #colorLiteral(red: 0.7118884921, green: 0.3784905672, blue: 0.7786803842, alpha: 1)]
    
    static func color(for objectID: String) -> UIColor
    {
        let hashValue = objectID.hashValue
        let index = abs(hashValue) % messageBackgroundColors.count
        return messageBackgroundColors[index]
    }
}
