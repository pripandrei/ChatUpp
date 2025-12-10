//
//  SkeletonAnimationAppearance.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 12/10/25.
//

import UIKit
import SkeletonView


struct SkeletonAnimationAppearance
{
    static func initiateSkeletonAnimation(for view: UIView)
    {
        let skeletonAnimationColor = ColorScheme.skeletonAnimationColor
        let skeletonItemColor = ColorScheme.skeletonItemColor
        view.showGradientSkeleton(usingGradient: .init(baseColor: skeletonItemColor, secondaryColor: skeletonAnimationColor), delay: TimeInterval(0), transition: SkeletonTransitionStyle.crossDissolve(0.3))
    }
    
    static func initiateSkeletonAnimation(for views: UIView...)
    {
        let skeletonAnimationColor = ColorScheme.skeletonAnimationColor
        let skeletonItemColor = ColorScheme.skeletonItemColor
        
        for view in views {
            view.showGradientSkeleton(usingGradient: .init(baseColor: skeletonItemColor, secondaryColor: skeletonAnimationColor), delay: TimeInterval(0), transition: SkeletonTransitionStyle.crossDissolve(0.3))
        }
    }
    
    static func terminateSkeletonAnimation(for view: UIView) {
        view.stopSkeletonAnimation()
        view.hideSkeleton(transition: .crossDissolve(0.25))
    }
    
    static func stopSkeletonAnimation(for views: UIView...)
    {
        for view in views {
            view.stopSkeletonAnimation()
            view.hideSkeleton(transition: .none)
        }
    }
}
