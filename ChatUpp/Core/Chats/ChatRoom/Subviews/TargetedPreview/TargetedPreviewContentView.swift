//
//  TargetedPreviewContentView.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 11/20/25.
//

import UIKit

class TargetedPreviewContentView: UIView
{
    private weak var contentView: UIView?
    private var displayLink: CADisplayLink?
    
    init(contentView: UIView)
    {
        self.contentView = contentView
        super.init(frame: contentView.bounds)
        self.backgroundColor = contentView.backgroundColor
        
        displayLink = CADisplayLink(target: self,
                                    selector: #selector(updateSnapshot))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func updateSnapshot()
    {
        guard let contentView = contentView else {
            displayLink?.invalidate()
            return
        }
        
        layer.contents = nil
        
        if let snapshot = contentView.snapshotView(afterScreenUpdates: false)
        {
            subviews.forEach { $0.removeFromSuperview() }
            snapshot.frame = bounds
            addSubview(snapshot)
        }
    }
    
    func cleanup()
    {
        contentView = nil
        displayLink?.invalidate()
        displayLink = nil
    }
    
    deinit {
        displayLink?.invalidate()
    }
}
