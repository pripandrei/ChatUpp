//
//  Untitled.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 1/28/26.
//

/// Use this object wrapper with caution, when you wish to silence swift 6+ concurrency erros/warrings
/// This wrapper should not be used for global shared resources(objects)!
///
struct UncheckedSendableWrapper<UnsafeObject>: @unchecked Sendable
{
    let object: UnsafeObject
    
    init(object: UnsafeObject) {
        self.object = object
    }
}
