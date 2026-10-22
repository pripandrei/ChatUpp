//
//  MessageMenuPresenter.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/22/26.
//

import UIKit
import SwiftUI

/// Presents the custom long-press message menu replacing the old system
/// `UIContextMenuConfiguration` flow:
///
/// 1. the room is covered by a dark blur,
/// 2. the tapped message bubble is captured as an image and flown to the
///    vertical center of the visible area (0.5s, keeping its horizontal slot),
/// 3. the reaction panel appears above the flown bubble (its own internal
///    entrance animation is kept untouched),
/// 4. the system-look menu card "hops up" below the flown bubble.
///
/// The overlay lives inside `rootView`, so the keyboard / sticker collection
/// (separate windows) are never affected. Tapping the blurred background or
/// running any menu row / reaction dismisses everything.
final class MessageMenuPresenter
{
    private enum Metrics
    {
        /// Reaction panel geometry, mirrored from the old targeted preview.
        static let panelSpacing: CGFloat = 14.0
        static let panelLeadingInset: CGFloat = 10.0
        /// Gap between the landed bubble and the menu card.
        static let menuGap: CGFloat = 8.0
        static let screenEdgeInset: CGFloat = 8.0
        /// Flight / blur fade duration in both directions.
        static let flightDuration: TimeInterval = 0.5
    }

    private let rootView: ChatRoomRootView
    private let message: Message
    private let bubbleSourceView: UIView
    private let optionGroups: [[MessageMenuOption]]
    private let onReactionSelection: (String) -> Void
    private let onFinished: () -> Void

    private var overlayView: UIView?
    private var dimmingView: UIView?
    private var blurView: UIVisualEffectView?
    private var bubblePreviewView: UIImageView?
    private var menuCardView: MessageMenuCardView?
    private var reactionPanelHostView: UIView?

    private var isPresented = false

    private var bubbleOriginFrame: CGRect = .zero
    private var bubbleLandedFrame: CGRect = .zero
    private var panelLandedFrame: CGRect = .zero
    private var menuLandedFrame: CGRect = .zero

    deinit
    {
        deinitDescription(for: Self.self)
    }

    init(rootView: ChatRoomRootView,
         message: Message,
         bubbleSourceView: UIView,
         optionGroups: [[MessageMenuOption]],
         onReactionSelection: @escaping (String) -> Void,
         onFinished: @escaping () -> Void)
    {
        self.rootView = rootView
        self.message = message
        self.bubbleSourceView = bubbleSourceView
        self.optionGroups = optionGroups
        self.onReactionSelection = onReactionSelection
        self.onFinished = onFinished
    }

    // MARK: - Presentation

    func present()
    {
        guard !isPresented else { return }
        guard let bubbleImage = captureBubbleImage() else
        {
            onFinished()
            return
        }
        isPresented = true

        bubbleOriginFrame = rootView.convert(bubbleSourceView.bounds,
                                             from: bubbleSourceView)
        computeLandedFrames()
        buildOverlayView(with: bubbleImage)
        animatePresentation()
    }

    func dismiss(completion: (() -> Void)? = nil)
    {
        guard isPresented else
        {
            completion?()
            return
        }
        isPresented = false

        /// The menu and the panel tuck away quickly while the bubble is
        /// still flying back home through the dissolving blur.
        UIView.animate(withDuration: 0.25,
                       delay: 0,
                       options: [.curveEaseIn, .beginFromCurrentState])
        {
            self.menuCardView?.transform = CGAffineTransform(scaleX: 0.4, y: 0.4)
            self.menuCardView?.alpha = 0
            self.reactionPanelHostView?.alpha = 0
        }

        UIView.animate(withDuration: Metrics.flightDuration,
                       delay: 0,
                       options: [.curveEaseInOut, .beginFromCurrentState],
                       animations: {
            self.blurView?.effect = nil
            self.dimmingView?.alpha = 0
            self.bubblePreviewView?.frame = self.bubbleOriginFrame
        }, completion: { _ in
            guard let overlay = self.overlayView else { return }
            overlay.removeFromSuperview()
            self.disposeOverlay()
            self.onFinished()
            completion?()
        })
    }

    // MARK: - Layout resolution

    /// Positions the landed bubble in the vertical middle of the area that is
    /// visually clear of the navigation bar and the input bar, then clamps it
    /// so the reaction panel (above) and the menu (below) both fit. The bubble
    /// keeps its original horizontal slot.
    private func computeLandedFrames()
    {
        let safeTop = rootView.safeAreaInsets.top
        let inputBarTop = max(rootView.inputBarContainer.frame.minY,
                              rootView.bounds.midY * 0.3)

        let panelSize = CGSize(width: 306, height: ReactionPanelView.panelHeight)
        let menuSize = MessageMenuCardView.preferredSize(for: optionGroups)

        let bandTop = safeTop + Metrics.screenEdgeInset
        let bandBottom = inputBarTop - Metrics.screenEdgeInset

        let minBubbleCenterY = bandTop + panelSize.height + Metrics.panelSpacing
            + bubbleOriginFrame.height / 2
        let maxBubbleCenterY = bandBottom - menuSize.height - Metrics.menuGap
            - bubbleOriginFrame.height / 2
        let preferredCenterY = bandTop + (bandBottom - bandTop) / 2

        var landedCenterY = preferredCenterY
        if minBubbleCenterY <= maxBubbleCenterY
        {
            landedCenterY = min(max(preferredCenterY, minBubbleCenterY), maxBubbleCenterY)
        }

        bubbleLandedFrame = CGRect(
            x: bubbleOriginFrame.minX,
            y: landedCenterY - bubbleOriginFrame.height / 2,
            width: bubbleOriginFrame.width,
            height: bubbleOriginFrame.height)

        panelLandedFrame = CGRect(
            x: Metrics.panelLeadingInset,
            y: bubbleLandedFrame.minY - Metrics.panelSpacing - panelSize.height,
            width: panelSize.width,
            height: panelSize.height)

        let centerX = rootView.bounds.width / 2
        let menuX = max(Metrics.screenEdgeInset,
                        min(centerX - menuSize.width / 2,
                            rootView.bounds.width - menuSize.width - Metrics.screenEdgeInset))
        menuLandedFrame = CGRect(
            x: menuX,
            y: bubbleLandedFrame.maxY + Metrics.menuGap,
            width: menuSize.width,
            height: menuSize.height)
    }

    // MARK: - Overlay construction

    private func buildOverlayView(with bubbleImage: UIImage)
    {
        let overlay = UIView(frame: rootView.bounds)
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        let dimming = UIView(frame: overlay.bounds)
        dimming.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        dimming.backgroundColor = .black
        dimming.alpha = 0
        overlay.addSubview(dimming)

        let blur = UIVisualEffectView(effect: nil)
        blur.frame = overlay.bounds
        blur.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        overlay.addSubview(blur)

        let bubblePreview = UIImageView(image: bubbleImage)
        bubblePreview.frame = bubbleOriginFrame
        bubblePreview.contentMode = .scaleToFill
        overlay.addSubview(bubblePreview)

        var reactionPanelView = ReactionPanelView()
        reactionPanelView.onReactionSelection = { [weak self] reactionEmoji in
            guard let self else { return }
            self.onReactionSelection(reactionEmoji)
            self.dismiss()
        }
        let reactionPanelHost = UIHostingController(rootView: reactionPanelView).view!
        reactionPanelHost.backgroundColor = .clear
        reactionPanelHost.frame = panelLandedFrame
        overlay.addSubview(reactionPanelHost)

        let menuCard = MessageMenuCardView(frame: menuLandedFrame, optionGroups: optionGroups)
        anchorLayerToTopCenter(menuCard)
        menuCard.transform = CGAffineTransform(scaleX: 0.4, y: 0.4)
        menuCard.alpha = 0
        menuCard.onSelectionHandled = { [weak self] in
            self?.dismiss()
        }
        overlay.addSubview(menuCard)

        let tapGesture = UITapGestureRecognizer(target: self,
                                                action: #selector(handleOverlayTap))
        overlay.addGestureRecognizer(tapGesture)

        overlayView = overlay
        dimmingView = dimming
        blurView = blur
        bubblePreviewView = bubblePreview
        reactionPanelHostView = reactionPanelHost
        menuCardView = menuCard

        rootView.addSubview(overlay)
    }

    private func disposeOverlay()
    {
        overlayView = nil
        dimmingView = nil
        blurView = nil
        bubblePreviewView = nil
        reactionPanelHostView = nil
        menuCardView = nil
    }

    // MARK: - Animations

    private func animatePresentation()
    {
        /// The bubble copy starts pixel-identically on top of the original,
        /// so fading the blur in and flying the copy away never leaves a
        /// message-less gap at any point.
        UIView.animate(withDuration: Metrics.flightDuration,
                       delay: 0,
                       options: [.curveEaseInOut, .beginFromCurrentState])
        {
            self.blurView?.effect = UIBlurEffect(style: .systemUltraThinMaterialDark)
            self.dimmingView?.alpha = 0.25
            self.bubblePreviewView?.frame = self.bubbleLandedFrame
        }

        /// The menu card "hops up" from the bottom of the flown bubble:
        /// its anchor point sits at the card's top edge, so scaling it up
        /// unfolds it downward out of the attachment point.
        UIView.animate(withDuration: 0.55,
                       delay: 0.18,
                       usingSpringWithDamping: 0.72,
                       initialSpringVelocity: 0.5,
                       options: [.beginFromCurrentState])
        {
            self.menuCardView?.transform = .identity
            self.menuCardView?.alpha = 1
        }
        /// the reaction panel entrance timing is internal to
        /// `ReactionPanelView` and kept exactly as it was.
    }

    /// Moves the layer anchor to the view's top-center so scale transforms
    /// unfold around the attachment edge; `position` is corrected for the
    /// anchor shift, all done before any transform is applied.
    private func anchorLayerToTopCenter(_ view: UIView)
    {
        let oldAnchor = view.layer.anchorPoint
        let oldPosition = view.layer.position
        view.layer.anchorPoint = CGPoint(x: 0.5, y: 0)
        view.layer.position = CGPoint(
            x: oldPosition.x + (0.5 - oldAnchor.x) * view.bounds.width,
            y: oldPosition.y + (0 - oldAnchor.y) * view.bounds.height)
    }

    // MARK: - Interaction

    @objc private func handleOverlayTap()
    {
        dismiss()
    }

    // MARK: - Snapshot

    private func captureBubbleImage() -> UIImage?
    {
        let sourceView = bubbleSourceView
        guard sourceView.bounds.width > 0, sourceView.bounds.height > 0 else { return nil }

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = UIScreen.main.scale
        format.opaque = false

        return UIGraphicsImageRenderer(bounds: sourceView.bounds, format: format).image
        { _ in
            sourceView.drawHierarchy(in: sourceView.bounds, afterScreenUpdates: false)
        }
    }
}
