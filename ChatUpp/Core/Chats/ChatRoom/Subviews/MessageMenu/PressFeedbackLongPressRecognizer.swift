//
//  PressFeedbackLongPressRecognizer.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/23/26.
//

import UIKit

/// `UILongPressGestureRecognizer` reports `.began` only after the hold
/// duration completes, which is too late to animate the press-in feedback.
/// This subclass reports the touch-down the moment fingers land on the view,
/// before the hold threshold, so the tapped bubble can start shrinking
/// (Telegram-style press imitation) while the finger is still down.
final class PressFeedbackLongPressRecognizer: UILongPressGestureRecognizer
{
    /// Fires once per press cycle, right after the fingers touch down.
    var onTouchDown: (() -> Void)?
    /// Fires whenever the fingers leave the surface - both normal lifts and
    /// system cancellations (scroll takeover, alert, etc.). This is the only
    /// signal guaranteed to arrive for EVERY ended press, including presses
    /// that never reached the hold threshold, where UIKit may silently fail
    /// the recognizer without delivering `.ended/.failed/.cancelled` states.
    var onTouchUp: (() -> Void)?

    private var notifiedTouchDown = false

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent)
    {
        super.touchesBegan(touches, with: event)
        guard !notifiedTouchDown else { return }
        notifiedTouchDown = true
        onTouchDown?()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent)
    {
        super.touchesEnded(touches, with: event)
        onTouchUp?()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent)
    {
        super.touchesCancelled(touches, with: event)
        onTouchUp?()
    }

    override func reset()
    {
        super.reset()
        notifiedTouchDown = false
    }
}
