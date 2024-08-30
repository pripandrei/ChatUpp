//
//  RealmDBManager.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 8/23/24.
//

import Foundation
import RealmSwift
import Realm

final class RealmDBManager {
    
    static var shared = RealmDBManager()
    
    private init() {}
    
    private let configuration = Realm.Configuration(
        schemaVersion: 8)
    
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
    
    public func retrieveObjects<T: Object>(ofType type: T.Type) -> [T] {
//        let objects = realmDB.objects(T.self)
        Array(realmDB.objects(T.self))
//        if objects.isEmpty {
//            return nil
//        } else {
//            return objects.toArray()
//        }
    }
    
    public func retrieveSingleObject<T: Object>(ofType type: T.Type, primaryKey: String) -> T? {
        return realmDB.object(ofType: type, forPrimaryKey: primaryKey)
    }
    
    public func update<T: Object>(object: T, update: (T) -> Void) {
        try! realmDB.write({
            update(object)
        })
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
//    public func addObserverToObject<T: Object>(object: T) {
//        notificationToke = object.observe { change in
//            switch change {
//            case .change(_, let properties):
//                for property in properties {
//                    
//                }
//            case .deleted: print("ads")
//            case .error(let error): print(error.localizedDescription)
//            }
//        }
//    }
    
    func transformObjectToResults<T: Object>(object: T) {
        
    }
}


extension Results {
    
    func toArray() -> [Element] {
        var results = [Element]()
        for item in self {
            results.append(item)
        }
        return results
    }
}
