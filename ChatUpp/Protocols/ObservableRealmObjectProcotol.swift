//
//  ObservableRealmObjectProcotol.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 1/25/25.
//
import Foundation
import RealmSwift
import Realm

protocol ObservableRealmObjectProcotol
{
    func observe<T: RLMObjectBase>(on queue: DispatchQueue?,
                                          _ block: @escaping (ObjectChange<T>) -> Void) -> NotificationToken
    
    func observe<T: RLMObjectBase>(keyPaths: [String]?,
                                          on queue: DispatchQueue?,
                                          _ block: @escaping (ObjectChange<T>) -> Void) -> NotificationToken
}

extension ObservableRealmObjectProcotol
{
    func observe<T: RLMObjectBase>(on queue: DispatchQueue? = nil,
                                   _ block: @escaping (ObjectChange<T>) -> Void) -> NotificationToken
    {
        self.observe(on: queue, block)
    }
    
    func observe<T: RLMObjectBase>(keyPaths: [String]? = nil,
                              on queue: DispatchQueue? = nil,
                              _ block: @escaping (ObjectChange<T>) -> Void) -> NotificationToken
    {
        self.observe(on: queue, block)
    }
}

extension EmbeddedObject: ObservableRealmObjectProcotol {}
extension Object: ObservableRealmObjectProcotol {}

