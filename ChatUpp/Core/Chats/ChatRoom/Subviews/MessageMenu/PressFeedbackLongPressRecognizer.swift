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

    private var notifiedTouchDown = false

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent)
    {
        super.touchesBegan(touches, with: event)
        guard !notifiedTouchDown else { return }
        notifiedTouchDown = true
        onTouchDown?()
    }

    override func reset()
    {
        super.reset()
        notifiedTouchDown = false
    }
}
