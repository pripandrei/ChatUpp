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

final class RealmDataBase {
    
    private var notificationToken: [NotificationToken]?
    
    static var shared = RealmDataBase()
    
    static private let schemaVersion: UInt64 = 14
    
    var realm: Realm?
    
    private init() {
        initiateDatabase()
    }
    
    private func initiateDatabase() 
    {
        Realm.Configuration.defaultConfiguration = createConfiguration()
        do {
            realm = try Realm()
        } catch {
            print("Error initiating Realm database: ", error.localizedDescription)
        }
    }
    
    private func createConfiguration() -> Realm.Configuration
    {
        return Realm.Configuration(
            schemaVersion: RealmDataBase.schemaVersion,
            migrationBlock: { [weak self] migration, oldSchemaVersion in
                
                if oldSchemaVersion < 11 { self?.migrateToVersion11(migration: migration) }
                if oldSchemaVersion < 13 { self?.migrateToVersion13(migration: migration) }
                if oldSchemaVersion < 14 { self?.migrateToVersion14(migration: migration) }
            }
        )
    }
    
    public func add<T: Object>(object: T) {
        try? realm?.write {
            realm?.add(object, update: .modified)
        }
    }
    
    public func retrieveObjects<T: Object>(ofType type: T.Type, filter: NSPredicate? = nil) -> [T] {
        guard var results = realm?.objects(type) else { return [] }
        
        if let predicate = filter {
            results = results.filter(predicate)
        }
        
        return Array(results)
    }

    public func retrieveSingleObject<T: Object>(ofType type: T.Type, primaryKey: String) -> T? {
        return realm?.object(ofType: type, forPrimaryKey: primaryKey)
    }
    
    public func update<T: Object>(object: T, update: (T) -> Void) {
        try? realm?.write {
            update(object)
        }
    }
    
    public func update<T: Object>(objectWithKey key: String, type: T.Type, update: (T) -> Void) {
        guard let object = retrieveSingleObject(ofType: type, primaryKey: key) else {return}
        
        try? realm?.write {
            update(object)
        }
    }
    
    public func delete<T: Object>(object: T) {
        try? realm?.write({
            realm?.delete(object)
        })
    }
}

//MARK: - Migrations

extension RealmDataBase
{
    private func migrateToVersion11(migration: Migration)
    {
        migration.enumerateObjects(ofType: Chat.className()) { oldObject, newObject in
            let oldKey = "members"
            let newKey = Chat.CodingKeys.participants.rawValue
            newObject![newKey] = oldObject![oldKey]
        }
    }
    
    private func migrateToVersion13(migration: Migration)
    {
        migration.enumerateObjects(ofType: Chat.className()) { oldObject, newObject in
            
            let key = "participants"
            var newParticipantList = [MigrationObject]()
            
            if let participantsID = oldObject![key] as? List<String>
            {
                for id in participantsID
                {
                    let participant = ChatParticipant(userID: id, unseenMessageCount: 0)
                    let migrationParticipantObject = migration.create(ChatParticipant.className(), value: participant)
                    newParticipantList.append(migrationParticipantObject)
                }
            }
            newObject![key] = newParticipantList
        }
    }
    
    private func migrateToVersion14(migration: Migration)
    {
        migration.enumerateObjects(ofType: "DBUser") { oldObject, newObject in
            guard let oldObject = oldObject else {return}
            
            let user = migration.create("User", value: [
                "id": oldObject["userId"] as? String ?? UUID().uuidString,
                "name": oldObject["name"] as? String?,
                "dateCreated": oldObject["dateCreated"] as? Date?,
                "email": oldObject["email"] as? String?,
                "photoUrl": oldObject["photoUrl"] as? String?,
                "phoneNumber": oldObject["phoneNumber"] as? String?,
                "isActive": oldObject["isActive"] as? Bool?,
                "lastSeen": oldObject["lastSeen"] as? Date?
            ])
        }
    }
}

//MARK: - Realm file path
extension RealmDataBase 
{
    static var realmFilePath: String? {
        guard let fileURL = Realm.Configuration.defaultConfiguration.fileURL else { return nil }
        return "Realm database file is located at: \(fileURL)"
    }
}


//MARK: Unused functions
//extension RealmDBManager {
//    public func create<T: Object>(object: T) -> T? {
//        return try? realm?.write {
//            realm?.create(T.self, value: object, update: .modified)
//        }
//    }


//    public func getObjectsCount<T: Object>(ofType type: T.Type, filter: NSPredicate? = nil) -> Int {
//        guard var result = realm?.objects(type) else {return 0}
//
//        if let predicate = filter {
//            result = result.filter(predicate)
//        }
//        
//        return result.count
//    }

//    public func addObserverToObjects<T: Object>(objects: Results<T>) {
//        let token = objects.observe { change in
//            switch change {
//            case .initial(let initialResults): print(initialResults)
//            case .update(let updateResults, let deletions, let insertions, let modifications): print("ads")
//            case .error(let error): print(error.localizedDescription)
//            }
//        }
//        notificationToken.append(token)
//    }
    
    
//    @Published var objectPropertyChange: RealmPropertyChange?
//    @Published var objectPropertyChange: PropertyChange?
    
//    public func addObserverToObject<T: Object>(object: T) {
//        let token = object.observe { change in
//            switch change {
//            case .change(_, let properties):
//                properties.forEach { property in
//                    guard let newValue = property.newValue as? String else { return }
////                    self.objectPropertyChange = property
//                }
//            case .deleted:
//                print("Object was deleted")
//            case .error(let error):
//                print(error.localizedDescription)
//            }
//        }
//        notificationToken?.append(token)
//    }

//}

//enum RealmPropertyChange {
//    case member(String)
//    case recentMessageID(String)
//}

