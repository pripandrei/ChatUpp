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
///    vertical center of the visible area (0.1s, keeping its horizontal slot),
/// 3. the reaction panel appears above the flown bubble (its own internal
///    entrance animation is kept untouched),
/// 4. the vertical menu card "hops up" below the flown bubble. The native
///    `UIEditMenuInteraction` pill was tried and rejected: it always renders
///    horizontally, text-only (that is its fixed edit-menu design).
///
/// The overlay lives inside `rootView`, so the keyboard / sticker collection
/// (separate windows) are never affected. Tapping the blurred background or
/// running any menu row / reaction dismisses everything.
///
/// Inherits `NSObject` because `UIGestureRecognizerDelegate` requires it.
final class MessageMenuPresenter: NSObject
{
    private enum Metrics
    {
        /// Reaction panel geometry, mirrored from the old targeted preview.
        static let panelSpacing: CGFloat = 14.0
        /// Gap between the landed bubble and the menu card.
        static let menuGap: CGFloat = 12.0
        static let screenEdgeInset: CGFloat = 8.0
        /// Flight / blur fade duration in both directions (0.2s per user
        /// preference: two times slower than the original 0.1s flight).
        static let flightDuration: TimeInterval = 0.2
        /// Clearance kept below the navigation bar when a bottom-half message
        /// has to be nudged out from under it.
        static let navBarClearance: CGFloat = 10.0
    }

    private let rootView: ChatRoomRootView
    private let message: Message
    private let bubbleSourceView: UIView
    private let optionGroups: [[MessageMenuOption]]
    private let onReactionSelection: (String) -> Void
    private let onFinished: () -> Void
    /// Full-size bubble snapshot captured at touch-down (before the shrink).
    /// When supplied, initiation skips the synchronous capture entirely, so
    /// the flight starts the instant the hold trips with no dead wait.
    private var preCapturedImage: UIImage?

    private var overlayView: UIView?
    private var dimmingView: UIView?
    private var blurView: UIVisualEffectView?
    private var bubblePreviewView: UIImageView?
    private var menuCardView: MessageMenuCardView?
    private var reactionPanelHostView: UIView?

    private var isPresented = false
    /// Guards `dismiss()` against re-entry from different dismissal paths
    /// (backdrop tap, row tap, reaction selection) firing close together.
    private var isDismissalRunning = false

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
         preCapturedImage: UIImage? = nil,
         onReactionSelection: @escaping (String) -> Void,
         onFinished: @escaping () -> Void)
    {
        self.rootView = rootView
        self.message = message
        self.bubbleSourceView = bubbleSourceView
        self.optionGroups = optionGroups
        self.preCapturedImage = preCapturedImage
        self.onReactionSelection = onReactionSelection
        self.onFinished = onFinished
    }

    // MARK: - Presentation

    func present()
    {
        guard !isPresented else { return }
        print("MENUPIPE[\(pipeTimestamp())]  preview present started (capture + overlay build)")

        let pressedTransform = bubbleSourceView.transform
        if preCapturedImage == nil
        {
            /// Fallback when no touch-down capture exists: the source may be
            /// mid press-in shrink, so capture at full size by resetting the
            /// transform around the synchronous capture, then restore the
            /// shrunk state. (The reset can flash the message at full size -
            /// that is why the touch-down pre-capture path is preferred.)
            bubbleSourceView.transform = .identity
            guard let captured = MessageMenuPresenter.captureBubbleImage(
                from: bubbleSourceView,
                afterScreenUpdates: true)
            else
            {
                bubbleSourceView.transform = pressedTransform
                onFinished()
                return
            }
            bubbleSourceView.transform = pressedTransform
            preCapturedImage = captured
        }
        isPresented = true

        /// The copy takes over the message visually - it sits pixel-for-pixel
        /// on top of the source at capture time - so the original goes dark
        /// for the whole session, leaving its table slot empty, and only
        /// reappears with the dismissal landing (where the copy lands exactly
        /// on its slot first, so the crossfade is invisible).
        bubbleSourceView.alpha = 0

        /// A view's `frame` (like a raw `convert(_:from:)` of bounds) is
        /// derived from bounds + center + TRANSFORM — with the press-in
        /// shrink active on the source, both come out ~10% scaled, which made
        /// the entire preview run at pressed-in size and the dismissal reveal
        /// jump to the true size without animation. The only transform-immune
        /// geometry is `center` (its position in the superview) plus the
        /// untransformed `bounds` size - rebuild the true original frame from
        /// those two.
        let sourceSuperview = bubbleSourceView.superview ?? rootView
        let centerInRoot = rootView.convert(bubbleSourceView.center, from: sourceSuperview)
        let trueSize = bubbleSourceView.bounds.size
        bubbleOriginFrame = CGRect(x: centerInRoot.x - trueSize.width / 2,
                                   y: centerInRoot.y - trueSize.height / 2,
                                   width: trueSize.width,
                                   height: trueSize.height)
        computeLandedFrames()
        guard let bubbleImage = preCapturedImage
        else
        {
            onFinished()
            return
        }
        buildOverlayView(with: bubbleImage, initialTransform: pressedTransform)
        animatePresentation()
        print("MENUPIPE[\(pipeTimestamp())]  preview ready - flight running")
    }

    func dismiss(completion: (() -> Void)? = nil)
    {
        guard isPresented, !isDismissalRunning else
        {
            return
        }
        isPresented = false
        isDismissalRunning = true
        print("MENUPIPE[\(pipeTimestamp())]  dismiss started")

        /// Bug #5 hardening: the outgoing copy must be purely positional.
        /// Freeze any residual layer animation and pin it to its full-size
        /// identity state, so the fly-back can never re-introduce a size
        /// change regardless of when the dismissal fires.
        if let copy = bubblePreviewView
        {
            copy.layer.removeAllAnimations()
            print("MENUPIPE[\(pipeTimestamp())]  dismissal - copy transform \(copy.transform.a), frame \(copy.frame), landed \(bubbleLandedFrame), origin \(bubbleOriginFrame)")
            copy.transform = .identity
        }

        /// The menu and the panel tuck away quickly while the bubble is
        /// still flying back home through the dissolving blur.
        UIView.animate(withDuration: 0.15,
                       delay: 0,
                       options: [.curveEaseIn, .beginFromCurrentState])
        {
            self.menuCardView?.transform = CGAffineTransform(scaleX: 0.4, y: 0.4)
            self.menuCardView?.alpha = 0
            self.reactionPanelHostView?.alpha = 0
        }

        /// Fly-back is center-only for the same reason as the presentation
        /// flight: mutating `frame` while any transform is active rewrites
        /// the copy's bounds, reintroducing the size change this dismissal
        /// must never have.
        UIView.animate(withDuration: Metrics.flightDuration,
                       delay: 0,
                       options: [.curveEaseInOut, .beginFromCurrentState],
                       animations: {
            self.bubblePreviewView?.center = CGPoint(x: self.bubbleOriginFrame.midX,
                                                     y: self.bubbleOriginFrame.midY)
        }, completion: nil)
        /// the blur outlasts the flight by a beat so the bubble is never
        /// left without a backdrop mid-exit (0.3s vs the 0.2s flight)
        UIView.animate(withDuration: 0.3,
                       delay: 0,
                       options: [.curveEaseInOut, .beginFromCurrentState],
                       animations: {
            self.blurView?.effect = nil
            self.dimmingView?.alpha = 0
        }, completion: { _ in
            guard let overlay = self.overlayView else { return }
            /// The original must reappear at its settled original size with
            /// no size animation at all: its transform was already restored
            /// at presentation time, and it is pinned here as a guarantee -
            /// the only animated change left is the copy's position fly-back.
            self.bubbleSourceView.transform = .identity
            self.bubbleSourceView.alpha = 1
            print("MENUPIPE[\(pipeTimestamp())]  reveal original - source transform \(self.bubbleSourceView.transform.a)")
            overlay.removeFromSuperview()
            self.disposeOverlay()
            self.onFinished()
            completion?()
        })
    }

    // MARK: - Layout resolution

    /// Positions the landed bubble. A message whose center sits at or above
    /// the screen's vertical middle stays exactly where it is (only pulled a
    /// few points down if the navigation bar covers it), while a message in
    /// the lower half flies up to the middle of the band clear of the
    /// navigation bar and the input bar, clamped so the reaction panel (above)
    /// and the menu (below) both fit. The bubble keeps its horizontal slot.
    private func computeLandedFrames()
    {
        let navBottom = rootView.safeAreaInsets.top
        let screenCenterY = rootView.bounds.midY
        let currentCenterY = bubbleOriginFrame.midY

        var landedCenterY = currentCenterY

        if currentCenterY > screenCenterY
        {
            /// message sits in the lower half: fly up to the band's middle
            let inputBarTop = max(rootView.inputBarContainer.frame.minY,
                                  rootView.bounds.midY * 0.3)
            let bandTop = navBottom + Metrics.screenEdgeInset
            let bandBottom = inputBarTop - Metrics.screenEdgeInset

            let panelSize = CGSize(width: 306, height: ReactionPanelView.panelHeight)
            let menuSize = MessageMenuCardView.preferredSize(for: optionGroups)

            let minBubbleCenterY = bandTop + panelSize.height + Metrics.panelSpacing
                + bubbleOriginFrame.height / 2
            let maxBubbleCenterY = bandBottom - menuSize.height
                - Metrics.menuGap - bubbleOriginFrame.height / 2
            let preferredCenterY = bandTop + (bandBottom - bandTop) / 2

            if minBubbleCenterY <= maxBubbleCenterY
            {
                landedCenterY = min(max(preferredCenterY, minBubbleCenterY), maxBubbleCenterY)
            }
        }
        else
        {
            /// at or above the middle: hold position; shift down only the
            /// minimum needed if the navigation bar covers (part of) the bubble
            let uncoveredTop = navBottom + Metrics.navBarClearance
            if bubbleOriginFrame.minY < uncoveredTop
            {
                landedCenterY = uncoveredTop + bubbleOriginFrame.height / 2
            }
        }

        let panelSize = CGSize(width: 306, height: ReactionPanelView.panelHeight)
        let menuSize = MessageMenuCardView.preferredSize(for: optionGroups)

        bubbleLandedFrame = CGRect(
            x: bubbleOriginFrame.minX,
            y: landedCenterY - bubbleOriginFrame.height / 2,
            width: bubbleOriginFrame.width,
            height: bubbleOriginFrame.height)

        /// The reaction panel's trailing edge mirrors the menu card's
        /// anchoring: it aligns with the message's trailing edge, clamped so
        /// it never exits the safe screen bounds.
        let panelX = max(Metrics.screenEdgeInset,
                         min(bubbleLandedFrame.maxX - panelSize.width,
                             rootView.bounds.width - panelSize.width - Metrics.screenEdgeInset))

        panelLandedFrame = CGRect(
            x: panelX,
            y: bubbleLandedFrame.minY - Metrics.panelSpacing - panelSize.height,
            width: panelSize.width,
            height: panelSize.height)

        /// The card's trailing edge anchors to the message's trailing edge
        /// (Telegram-style), only clamped so it never exits the safe screen
        /// bounds (incoming bubbles may leave no room to the right).
        let menuX = max(Metrics.screenEdgeInset,
                        min(bubbleLandedFrame.maxX - menuSize.width,
                            rootView.bounds.width - menuSize.width - Metrics.screenEdgeInset))
        menuLandedFrame = CGRect(
            x: menuX,
            y: bubbleLandedFrame.maxY + Metrics.menuGap,
            width: menuSize.width,
            height: menuSize.height)
    }

    // MARK: - Overlay construction

    private func buildOverlayView(with bubbleImage: UIImage, initialTransform: CGAffineTransform)
    {
        /// The overlay must sit ABOVE the navigation bar, which lives in the
        /// navigation controller's own hierarchy outside `rootView` - an
        /// overlay inside `rootView` could never cover it. Hosting the blur
        /// in the window covers the entire screen (navigation bar, status
        /// bar, input bar); the keyboard / sticker collection are separate
        /// windows and stay untouched. The content container preserves
        /// `rootView`'s coordinate space, so every landed frame and the
        /// position math keep working unchanged.
        let host = rootView.window ?? rootView
        let overlay = UIView(frame: host.bounds)
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

        let contentContainer = UIView(frame: rootView.convert(rootView.bounds, to: host))
        contentContainer.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        overlay.addSubview(contentContainer)

        let bubblePreview = UIImageView(image: bubbleImage)
        bubblePreview.frame = bubbleOriginFrame
        bubblePreview.transform = initialTransform
        bubblePreview.contentMode = .scaleToFill
        contentContainer.addSubview(bubblePreview)

        var reactionPanelView = ReactionPanelView()
        reactionPanelView.onReactionSelection = { [weak self] reactionEmoji in
            guard let self else { return }
            self.onReactionSelection(reactionEmoji)
            self.dismiss()
        }
        let reactionPanelHost = UIHostingController(rootView: reactionPanelView).view!
        reactionPanelHost.backgroundColor = .clear
        reactionPanelHost.frame = panelLandedFrame
        contentContainer.addSubview(reactionPanelHost)

        let menuCard = MessageMenuCardView(frame: menuLandedFrame, optionGroups: optionGroups)
        anchorLayerToTopCenter(menuCard)
        menuCard.transform = CGAffineTransform(scaleX: 0.4, y: 0.4)
        menuCard.alpha = 0
        menuCard.onSelectionHandled = { [weak self] in
            self?.dismiss()
        }
        contentContainer.addSubview(menuCard)

        let tapGesture = UITapGestureRecognizer(target: self,
                                                action: #selector(handleOverlayTap))
        tapGesture.delegate = self
        overlay.addGestureRecognizer(tapGesture)

        overlayView = overlay
        dimmingView = dimming
        blurView = blur
        bubblePreviewView = bubblePreview
        reactionPanelHostView = reactionPanelHost
        menuCardView = menuCard

        host.addSubview(overlay)
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
        UIView.animate(withDuration: Metrics.flightDuration,
                       delay: 0,
                       options: [.curveEaseInOut, .beginFromCurrentState])
        {
            self.blurView?.effect = UIBlurEffect(style: .systemUltraThinMaterialDark)
            self.dimmingView?.alpha = 0.25
            /// The flight moves CENTER only. Setting `frame` on a view that
            /// still carries the pressed transform makes UIKit divide the
            /// requested size by the active scale (301 -> 327 points), which
            /// inflated the copy's bounds to ~+8.7% and left the preview
            /// message permanently bigger than the original. The size lives
            /// in bounds (set once at build time from the true origin size)
            /// and is never changed again.
            self.bubblePreviewView?.center = CGPoint(x: self.bubbleLandedFrame.midX,
                                                     y: self.bubbleLandedFrame.midY)
        }

        /// The copy expands from its press-in shrunk scale back to the full
        /// original size. Critically a non-overshooting spring (damping 1.0):
        /// an elastic damping here pops the copy past 1.0 and back within a
        /// fraction of a second - visible as a size right at the moment the
        /// press-in state completes - and its residual motion would still be
        /// settling during an early dismissal, reading there as the press-in
        /// animation "happening again" while the copy flies home.
        UIView.animate(withDuration: 0.25,
                       delay: 0,
                       usingSpringWithDamping: 1.0,
                       initialSpringVelocity: 0.1,
                       options: [.beginFromCurrentState])
        {
            self.bubblePreviewView?.transform = .identity
        }

        /// The real bubble underneath springs back from its press-in shrink
        /// to full size as well (hidden during the session, the geometry
        /// stays consistent for the dismissal landing). Non-overshooting for
        /// the same reason: on dismissal it must already sit settled at
        /// identity, with no wobble left to reveal.
        UIView.animate(withDuration: 0.3,
                       delay: 0,
                       usingSpringWithDamping: 1.0,
                       initialSpringVelocity: 0.1,
                       options: [.beginFromCurrentState])
        {
            self.bubbleSourceView.transform = .identity
        }

        /// The menu card "hops up" from the bottom of the flown bubble:
        /// its anchor point sits at the card's top edge, so scaling it up
        /// unfolds it downward out of the attachment point.
        UIView.animate(withDuration: 0.4,
                       delay: 0.08,
                       usingSpringWithDamping: 0.75,
                       initialSpringVelocity: 0.6,
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

    /// Renders the given view at full size. `afterScreenUpdates: false`
    /// snapshots the last committed state (cheap, no forced screen flush -
    /// used at touch-down while the view is still at its idle identity
    /// transform); `true` waits for pending updates (fallback path, where the
    /// caller resets/restores the transform around the call).
    static func captureBubbleImage(from sourceView: UIView,
                                   afterScreenUpdates: Bool) -> UIImage?
    {
        guard sourceView.bounds.width > 0, sourceView.bounds.height > 0 else { return nil }

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = UIScreen.main.scale
        format.opaque = false

        return UIGraphicsImageRenderer(bounds: sourceView.bounds, format: format).image
        { _ in
            sourceView.drawHierarchy(in: sourceView.bounds,
                                     afterScreenUpdates: afterScreenUpdates)
        }
    }
}

// MARK: - Backdrop tap delegate

extension MessageMenuPresenter: UIGestureRecognizerDelegate
{
    /// Taps landing on the menu card belong to the card's drag-select
    /// tracker (press a row, slide, lift to select); the backdrop
    /// dismiss-tap must therefore not receive touches inside the card.
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldReceive touch: UITouch
    ) -> Bool
    {
        guard let menuCard = menuCardView, let overlay = overlayView else { return true }
        return !menuCard.frame.contains(touch.location(in: overlay))
    }
}
