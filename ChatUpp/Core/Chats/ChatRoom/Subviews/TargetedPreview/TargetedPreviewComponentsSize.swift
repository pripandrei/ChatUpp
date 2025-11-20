//
//  TargetedPreview.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 11/20/25.
//

import UIKit

struct TargetedPreviewComponentsSize
{
    static let reactionHeight: CGFloat = 45.0
    static let spaceReactionHeight: CGFloat = 14.0
    static let menuHeight: CGFloat = 200
    
    static func calculateMaxSnapshotHeight(from view: UIView) -> CGFloat
    {
        return min(view.bounds.height,
                   UIScreen.main.bounds.height -
                   self.reactionHeight -
                   self.spaceReactionHeight -
                   self.menuHeight)
    }
    
    static func getSnapshotContainerHeight(_ snapshot: UIView) -> CGFloat
    {
        return snapshot.bounds.height +
        TargetedPreviewComponentsSize.reactionHeight + TargetedPreviewComponentsSize.spaceReactionHeight
    }
}
