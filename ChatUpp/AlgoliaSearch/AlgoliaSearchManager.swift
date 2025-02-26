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
    private let usersClient = SearchClient(appID: "TRVTKK4YUR", apiKey: "5ba2aee5ee2c0879fcd16f112a66e821")
    private let groupsClient = SearchClient(appID: "TRVTKK4YUR", apiKey: "6c88391e8a0c760cd91bfa9d49e88f4a")
  
    private lazy var usersIndex = usersClient.index(withName: "Users")
    private lazy var groupsIndex = groupsClient.index(withName: "Groups")
    
    private init() { }

    func performSearch(_ searchText: String) async -> AlgoliaSearchResult?
    {
        let query = Query(searchText)
        
        do {
            let users = try await searchInUsersIndex(withQuery: query)
            let groups = try await searchInGroupsIndex(withQuery: query)
            return .init(users: users, groups: groups)
        } catch {
            print("Error while searching for index field: ", error)
            return nil
        }
    }
    
    private func searchInUsersIndex(withQuery query: Query) async throws -> [User]
    {
        usersIndex.setupSettings()
        
        let result = try usersIndex.search(query: query)
        
        var users: [User] = []
        
        for hitJson in result.hits {
            if let userID = hitJson.object["user_id"]?.object() as? String {
                let user = try await FirestoreUserService.shared.getUserFromDB(userID: userID)
                users.append(user)
            }
        }
        return users
    }
    
    private func searchInGroupsIndex(withQuery query: Query) async throws -> [Chat]
    {
        groupsIndex.setupSettings()
        
        let result = try groupsIndex.search(query: query)
        var groups: [Chat] = []
        
        for hitJson in result.hits
        {
            let groupID = hitJson.objectID.description
            let groupChat = try await FirebaseChatService.shared.fetchChat(withID: groupID)
            groups.append(groupChat)
        }
        return groups
    }
}

struct AlgoliaSearchResult
{
    let users: [User]
    let groups: [Chat]
}

extension Index 
{
    func setupSettings() {
        let settings = Settings().set(\.typoTolerance, to: false)
        do {
            try self.setSettings(settings)
        } catch {
            print("Could not set index settings", error.localizedDescription)
        }
    }
}

//struct AlgoliaResultData
//{
//    let userID: String
//    let name: String
//    let profileImageLink: String
//}
