//
//  ConversationMessagePaginator.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 7/17/25.
//

import UIKit
import Foundation

actor RemoteMessagePaginator
{
    func perform(_ block: () async -> Void) async
    {
        await block()
    }
}


actor MessageSeenStatusUodater
{
    func perform(_ block: () async -> Void) async
    {
        await block()
    }
}
