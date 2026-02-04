//
//  Untitled.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 2/4/26.
//

protocol RelayoutNotifying: AnyObject
{
    var onRelayoutNeeded: (() -> Void)? { get set }
}
