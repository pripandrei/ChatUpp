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
    
    /// The latest captured frame of the original content; kept as an image so
    /// consumers (context menu dismissal) can clone the current visual state
    /// without re-parenting this live view out of the highlighted preview.
    private(set) var renderedImage: UIImage?
    
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
        
        guard let image = TargetedPreviewContentView.stillImage(from: contentView) else { return }
        
        /// Atomic swap of the rendered frame.
        ///
        /// The former approach (`snapshotView` + wipe `layer.contents` +
        /// remove/add a snapshot subview on every tick) scraped the render
        /// tree per frame; whenever UIKit was busy with the context menu
        /// presentation or a layout pass, a tick produced an empty or blank
        /// snapshot while the previous content was already gone - surfacing
        /// as the preview visibly disappearing for a moment. Assigning
        /// `layer.contents` commits the new content instantly, so there is
        /// never an intermediate blank state.
        self.renderedImage = image
        self.layer.contents = image.cgImage
    }
    
    /// Renders `view`'s current visual state synchronously, regardless of what
    /// UIKit is doing with the render tree at this moment.
    static func stillImage(from view: UIView) -> UIImage?
    {
        guard view.bounds.width > 0, view.bounds.height > 0 else { return nil }
        
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = UIScreen.main.scale
        return UIGraphicsImageRenderer(size: view.bounds.size, format: format).image
        { _ in
            view.drawHierarchy(in: CGRect(origin: .zero, size: view.bounds.size),
                               afterScreenUpdates: false)
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
