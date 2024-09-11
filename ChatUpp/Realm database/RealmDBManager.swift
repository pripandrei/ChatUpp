//
//  RealmDBManager.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 8/23/24.
//

import Foundation
import RealmSwift
import Realm

enum RealmRetrieveError: Error, LocalizedError {
    case objectNotPresent
    case chatNotPresent
    case memberNotPresent
    case messageNotPresent
    case imageNotPresent
    
    var errorDescription: String? {
        switch self {
        case .objectNotPresent: return "object not present"
        case .chatNotPresent: return "chat not present"
        case .memberNotPresent: return "member not present"
        case .messageNotPresent: return "message not present"
        case .imageNotPresent: return "image not present"
        }
    }
}

final class RealmDBManager {
    
    static var shared = RealmDBManager()
    
    private init() {}
    
    private let configuration = Realm.Configuration(schemaVersion: 9)
    
    private var notificationToke: NotificationToken?
    
    var realmDB: Realm {
        Realm.Configuration.defaultConfiguration = configuration
        return try! Realm()
    }
    
    public func add<T: Object>(object: T) {
        try? realmDB.write {
            realmDB.add(object, update: .modified)
        }
    }
    
    public func create<T: Object>(object: T) {
        try? realmDB.write {
            realmDB.create(T.self, value: object, update: .modified)
        }
    }
    
    public func retrieveObjects<T: Object>(ofType type: T.Type) -> [T] {
//        return  Array(realmDB.objects(T.self).map { $0.freeze() })
        Array(realmDB.objects(T.self))
    }
    
    public func retrieveSingleObject<T: Object>(ofType type: T.Type, primaryKey: String) -> T? {
        let realm = try? Realm()
        return realm?.object(ofType: type, forPrimaryKey: primaryKey)
    }
    
    
    public func update<T: Object>(object: T, update: (T) -> Void) {
        try? realmDB.write {
            update(object)
        }
    }
    
    public func update<T: Object>(objectWithKey key: String, type: T.Type, update: (T) -> Void) {
        guard let object = retrieveSingleObject(ofType: type, primaryKey: key) else {return}
        
        try? realmDB.write {
            update(object)
        }
    }

//    public func addObserverToObjects<T: Object>(objects: Results<T>) {
//        notificationToke = objects.observe { change in
//            switch change {
//            case .initial(let initialResults): print(initialResults)
//            case .update(let updateResults, let deletions, let insertions, let modifications): print("ads")
//            case .error(let error): print(error.localizedDescription)
//            }
//        }
//    }
//    
    public func addObserverToObject<T: Object>(object: T) {
        notificationToke = object.observe { change in
            switch change {
            case .change(_, let properties):
                for property in properties {
                    
                }
            case .deleted: print("ads")
            case .error(let error): print(error.localizedDescription)
            }
        }
    }
}
