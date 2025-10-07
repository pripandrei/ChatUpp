import Foundation
import Core
import Search

final class AlgoliaSearchManager {
    static let shared = AlgoliaSearchManager()
    
    //TODO: ID, apiKEY should not be here
    private let usersClient: SearchClient
    private let groupsClient: SearchClient
    
    private init()
    {
        usersClient = try! SearchClient(appID: "TRVTKK4YUR", apiKey: "5ba2aee5ee2c0879fcd16f112a66e821")
        groupsClient = try! SearchClient(appID: "TRVTKK4YUR", apiKey: "6c88391e8a0c760cd91bfa9d49e88f4a")
    }
    
    func performSearch(_ searchText: String) async -> AlgoliaSearchResult? {
        do {
            let users = try await searchInUsersIndex(withQuery: searchText)
            let groups = try await searchInGroupsIndex(withQuery: searchText)
            return .init(users: users, groups: groups)
        } catch {
            print("Error while searching for index field: ", error)
            return nil
        }
    }
    
    private func searchInUsersIndex(withQuery query: String) async throws -> [User]
    {
        // Create search request 
        let searchRequest = SearchForHits(
            query: query,
            typoTolerance: .searchTypoToleranceEnum(.false),
            indexName: "Users"
        )
        
        // Perform search - need to specify Hit type
        let response: SearchResponses<Hit> = try await usersClient.search(
            searchMethodParams: SearchMethodParams(
                requests: [SearchQuery.searchForHits(searchRequest)]
            )
        )
        
        var users: [User] = []
        
        // Process results
        if let firstResult = response.results.first,
           case .searchResponse(let searchResponse) = firstResult
        {
            for hit in searchResponse.hits
            {
                if let userIDAnyCodable = hit["user_id"],
                   let userID = userIDAnyCodable.value as? String
                {
                    let user = try await FirestoreUserService.shared.getUserFromDB(userID: userID)
                    users.append(user)
                }
            }
        }
        
        return users
    }
    
    private func searchInGroupsIndex(withQuery query: String) async throws -> [Chat]
    {
        // Create search request
        let searchRequest = SearchForHits(
            query: query,
            typoTolerance: .searchTypoToleranceEnum(.false),
            indexName: "Chats"
        )
        
        // Perform search - need to specify Hit type
        let response: SearchResponses<Hit> = try await groupsClient.search(
            searchMethodParams: SearchMethodParams(
                requests: [SearchQuery.searchForHits(searchRequest)]
            )
        )
        
        var groups: [Chat] = []
        
        // Process results
        if let firstResult = response.results.first,
           case .searchResponse(let searchResponse) = firstResult
        {
            for hit in searchResponse.hits {
                // objectID is directly accessible as a property
                let groupID = hit.objectID
                let groupChat = try await FirebaseChatService.shared.fetchChat(withID: groupID)
                groups.append(groupChat)
            }
        }
        
        return groups
    }
}

struct AlgoliaSearchResult {
    let users: [User]
    let groups: [Chat]
}
