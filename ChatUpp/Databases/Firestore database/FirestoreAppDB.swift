//
//  FirestoreAppDB.swift
//  ChatUpp
//
//  Central Firestore accessor. Prod uses the named Enterprise edition database
//  (Enterprise edition does not support the (default) database).
//

import Foundation
import FirebaseFirestore

extension Firestore
{
    static var appDB: Firestore
    {
        #if PROD
        return Firestore.firestore(database: "chatupp-prod-db")
        #else
        return Firestore.firestore()
        #endif
    }
}
