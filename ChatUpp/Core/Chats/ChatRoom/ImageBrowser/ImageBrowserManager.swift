//
//  ImageBrowserManager.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 8/27/25.
//

import UIKit
import Foundation
import SKPhotoBrowser

struct MediaItem
{
    let imagePath: URL
    let imageText: String?
}

final class SKPhotoBrowserManager
{
    private var selectedImageView: UIImageView?
    private var willDissmissBrowser: Bool = false

    func presentPhotoBrowser(on viewController: UIViewController,
                             usingItems mediaItems: [MediaItem],
                             initialIndex: Int,
                             originImageView: UIImageView)
    {
        self.selectedImageView = originImageView
        
        let photos = mediaItems.map { item in
            let photo = SKLocalPhoto.photoWithImageURL(item.imagePath.path())
            photo.caption = item.imageText
            return photo
        }
        
        SKPhotoBrowserOptions.bounceAnimation = true

        let browser = SKPhotoBrowser(photos: photos,
                                     initialPageIndex: initialIndex)
        browser.delegate = self
        
        setToolbarAppearanceClear(for: browser) // ios 26 adds background to toolbar 🤷, set it to clear
        
        viewController.present(browser,
                               animated: true)
    }
    
    private func setToolbarAppearanceClear(for browser: SKPhotoBrowser)
    {
        if let toolbar = browser.view.subviews.first(where: { $0 is UIToolbar }) as? UIToolbar
        {
            let appearance = UIToolbarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .clear
            toolbar.standardAppearance = appearance
            toolbar.scrollEdgeAppearance = appearance
        }
    }
}

//MARK: - SKPhotoBrowser Delegate
extension SKPhotoBrowserManager: SKPhotoBrowserDelegate
{
    func didShowPhotoAtIndex(_ browser: SKPhotoBrowser,
                             index: Int)
    {
        if index > 0 {
            let previous = browser.photos[index - 1]
            as? SKLocalPhoto
            previous?.unloadUnderlyingImage()
        }
        if index < (browser.photos.count) - 1 {
            let next = browser.photos[index + 1] as? SKLocalPhoto
            next?.unloadUnderlyingImage()
        }
        
        if browser.initPageIndex == index {
            selectedImageView?.layer.opacity = 0.0
        } else {
            selectedImageView?.layer.opacity = 1.0
        }
    }
    
    func willDismissAtPageIndex(_ index: Int) {
        willDissmissBrowser = true
    }
    
    func viewForPhoto(_ browser: SKPhotoBrowser,
                      index: Int) -> UIView?
    {
        if browser.initPageIndex == index
        {
            selectedImageView?.layer.cornerRadius = willDissmissBrowser ?
            13.0 : 0.0
            return selectedImageView
        }
        return nil
    }
    
    func didDismissAtPageIndex(_ index: Int)
    {
        selectedImageView?.layer.opacity = 1.0
        selectedImageView = nil
        willDissmissBrowser = false
    }
}

extension SKLocalPhoto
{
    func unloadUnderlyingImage() {
        underlyingImage = nil   // release memory when scrolled offscreen
    }
}
