//
//  DisplayLinkProxy.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 9/22/25.
//

import UIKit

// MARK: - DisplayLinkProxy
final class DisplayLinkProxy
{
    weak var target: AnyObject?
    let selector: Selector
    
    init(target: AnyObject, selector: Selector) {
        self.selector = selector
        self.target = target
    }
    
    @objc func onDisplayLink(_ link: CADisplayLink) {
        _ = target?.perform(selector, with: link)
    }
}
