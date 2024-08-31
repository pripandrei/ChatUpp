//
//  AlgoliaSearchManager.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 11/15/23.
//

import Foundation
import AlgoliaSearchClient

final class AlgoliaSearchManager {
    
    static let shared = AlgoliaSearchManager()
    
    //TODO: ID, apiKEY should not be here 
    private let client = SearchClient(appID: "TRVTKK4YUR", apiKey: "5ba2aee5ee2c0879fcd16f112a66e821")
  
    private lazy var index = client.index(withName: "Users")
    
    private init() { }
    
    func performSearch(_ searchText: String) async -> [DBUser] {
        let text = Query(searchText)
        do {
            index.setupSettings()
            
            let result = try index.search(query: text)
            
            var users: [DBUser] = []
            
            for hitJson in result.hits {
                if let userID = hitJson.object["user_id"]?.object() as? String {
                    do {
                        let user = try await UserManager.shared.getUserFromDB(userID: userID)
                        users.append(user)
                    } catch {
                        print("Error fetching user for ID \(userID): \(error)")
                    }
                }
            }
            return users
        } catch {
            print("Error while searching for index field: ", error)
            return []
        }
    }

}

struct AlgoliaResultData {
    let userID: String
    let name: String
    let profileImageLink: String
}


extension Index {
    func setupSettings() {
        let settings = Settings().set(\.typoTolerance, to: false)
        do {
            try self.setSettings(settings)
        } catch {
            print("Could not set index settings", error.localizedDescription)
        }
    }
}
