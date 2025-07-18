//
//  RealmDBManager.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 8/23/24.
//

import Foundation
import RealmSwift
import Realm
import Combine


final class RealmDataBase {
    
    private var notificationTokens: [NotificationToken]?
    
    static var shared = RealmDataBase()
    
    static private let schemaVersion: UInt64 = 21
    
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
            print("Error initiating Realm database: ", error)
        }
    }
    
    func retrieveObjects<T: Object>(ofType type: T.Type, filter: NSPredicate? = nil) -> Results<T>?
    {
        var results = realm?.objects(type)
        
        if let predicate = filter {
            results = results?.filter(predicate)
        }
        
        return results
    }
    
    // for background
    func retrieveObjectsTest<T: Object>(ofType type: T.Type, filter: NSPredicate? = nil) -> Results<T>?
    {
        let realm = try! Realm()
        var results = realm.objects(type)
        
        if let predicate = filter {
            results = results.filter(predicate)
        }
        
        return results
    }

    func retrieveSingleObject<T: Object>(ofType type: T.Type, primaryKey: String) -> T? {
//        let realm = try! Realm()
        return realm?.object(ofType: type, forPrimaryKey: primaryKey)
    }
    
    /// for background
    func retrieveSingleObjectTest<T: Object>(ofType type: T.Type, primaryKey: String) -> T?
    {
        let realm = try! Realm()
        return realm.object(ofType: type, forPrimaryKey: primaryKey)
    }
    
    /// for background
    func updateTest<T: Object>(object: T, update: (T) -> Void)
    {
        let realm = try! Realm()
        try? realm.write {
            update(object)
        }
    }
    
    /// for background
    func addTest<T: Object>(object: T) {
        let realm = try! Realm()
        try? realm.write {
            realm.add(object, update: .modified)
        }
    }
    
    func addMultipleTest<T: Object>(objects: [T]) {
        let realm = try! Realm()
        try? realm.write {
            realm.add(objects, update: .modified)
        }
    }
    
    
    func update<T: Object>(object: T, update: (T) -> Void) {
        try? realm?.write {
            update(object)
        }
    }
    
    // for background
    func updateBackground<T: Object>(object: T, update: (T) -> Void)
    {
        let realm = try! Realm()
        try? realm.write {
            update(object)
        }
    }
    
    // for background
    func update<T: Object>(objects: [T], update: ([T]) -> Void)
    {
        let realm = try! Realm()
        
        try? realm.write {
            update(objects)
        }
    }
    
    func update<T: Object>(objectWithKey key: String,
                           type: T.Type, update: (T) -> Void)
    {
        guard let object = retrieveSingleObject(ofType: type, primaryKey: key) else {return}
        
        try? realm?.write {
            update(object)
        }
    }
    
    /// - add single object
    func add<T: Object>(object: T) {
        try? realm?.write {
            realm?.add(object, update: .modified)
        }
    }
    
    /// - add multiple objects
    func add<T: Object>(objects: [T]) {
        try? realm?.write {
            realm?.add(objects, update: .modified)
        }
    }
    
    func delete<T: Object>(object: T) {
        try? realm?.write({
            realm?.delete(object)
        })
    }
    
    func makeThreadSafeObject<T: Object>(object: T) -> ThreadSafeReference<T> {
        return ThreadSafeReference(to: object)
    }
    
    func resolveThreadSafeObject<T: Object>(threadSafeObject: ThreadSafeReference<T>) -> T?
    {
        let realm = try! Realm()
        return realm.resolve(threadSafeObject)
    }
}

//MARK: - realm object observer
extension RealmDataBase
{
    func observeChanges<T>(for object: T) -> AnyPublisher<(PropertyChange, RLMObjectBase), Never>
    {
        let subject = PassthroughSubject<(PropertyChange, RLMObjectBase), Never>()
        
        let token: NotificationToken? =
        {
            switch object {
            case let realmObject as Object:
                return realmObject.observe { change in
                    if case .change(let object, let properties) = change {
                        properties.forEach { property in
                            subject.send((property, object))
                        }
                    }
                }
            case let embeddedObject as EmbeddedObject:
                return embeddedObject.observe { change in
                    if case .change(let object, let properties) = change {
                        properties.forEach { property in
                            subject.send((property, object))
                        }
                    }
                }
            default:
                return nil
            }
        }()
        
        guard let token = token else { return Empty().eraseToAnyPublisher() }
        
        return subject
            .handleEvents(receiveCancel: { [weak self] in
                self?.invalidateToken(token)
            })
            .eraseToAnyPublisher()
    }
    
    private func invalidateToken(_ token: NotificationToken) {
        token.invalidate()
        notificationTokens?.removeAll { $0 == token }
    }
}

//MARK: - Realm configuration
extension RealmDataBase
{
    private func createConfiguration() -> Realm.Configuration
    {
        return Realm.Configuration(
            schemaVersion: RealmDataBase.schemaVersion,
            migrationBlock: { [weak self] migration, oldSchemaVersion in
                if oldSchemaVersion < 11 { self?.migrateToVersion11(migration: migration) }
                if oldSchemaVersion < 13 { self?.migrateToVersion13(migration: migration) }
                if oldSchemaVersion < 14 { self?.migrateToVersion14(migration: migration) }
                if oldSchemaVersion < 15 { self?.migrateToVersion15(migration: migration) }
                if oldSchemaVersion < 16 { self?.migrateToVersion16(migration: migration) }
                if oldSchemaVersion < 17 { self?.migrateToVersion17(migration: migration) }
                if oldSchemaVersion < 18 { self?.migrateToVersion18(migration: migration) }
                if oldSchemaVersion < 19 { self?.migrateToVersion19(migration: migration) }
            },
            objectTypes: [Chat.self, User.self, Message.self, MessageImageSize.self, ChatParticipant.self, Reaction.self]
        )
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
    
    private func migrateToVersion15(migration: Migration)
    {
        migration.enumerateObjects(ofType: Chat.className())  { oldChat, newChat in
            
            guard let oldParticipants = oldChat?["participants"] as? List<Object> else {return}
            
            let newParticipants = List<ChatParticipant>()
            
            for oldParticipant in oldParticipants {
                
                let newParticipant = ChatParticipant()
                
                newParticipant.userID = oldParticipant["user_id"] as! String
                newParticipant.unseenMessagesCount = oldParticipant["unseen_messages_count"] as? Int ?? 0
                newParticipant.isDeleted = false
                
                newParticipants.append(newParticipant)
            }
            
            newChat?["participants"] = newParticipants
        }
    }
    
    private func migrateToVersion16(migration: Migration)
    {
        migration.enumerateObjects(ofType: User.className())  { oldUser, newUser in
            newUser?["nickname"] = ""
        }
    }
    
    private func migrateToVersion17(migration: Migration)
    {
        migration.enumerateObjects(ofType: Message.className()) { oldMessage, newMessage in
            
            guard let imageSize = oldMessage?["imageSize"] as? MessageImageSize else {return}
            
            let newImageSize = migration.create(MessageImageSize.className(), value: imageSize)
            
            newMessage?["imageSize"] = newImageSize
        }
    }
    
    private func migrateToVersion18(migration: Migration)
    {
        migration.enumerateObjects(ofType: Message.className()) { oldObject, newObject in
            
            newObject?["seenBy"] = List<String>()
            
            if let oldMessageSeen = oldObject?["messageSeen"] as? Bool {
                newObject?["messageSeen"] = oldMessageSeen
            } else {
                newObject?["messageSeen"] = nil
            }
        }
    }
    
    private func migrateToVersion19(migration: Migration)
    {
        migration.enumerateObjects(ofType: Message.className()) { oldObject, newObject in
            newObject?["type"] = "text"
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

extension Results
{
    func toArray() -> [Element] {
        return Array(self)
    }
}

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
        case .messageNotPresent: return "message not present (is nil)"
        case .imageNotPresent: return "image not present"
        }
    }
}
