import Foundation
import Core
import Search

final class AlgoliaSearchManager
{
    static let shared = AlgoliaSearchManager()
    
    private let usersClient: SearchClient
    private let groupsClient: SearchClient
    
    private init()
    {
        guard let keys = AlgoliaAPIKeys.load() else
        {
            fatalError("⚠️ Missing Algolia credentials — please configure APIKeys.plist")
        }
        
        usersClient = try! SearchClient(appID: keys.appID, apiKey: keys.usersKey)
        groupsClient = try! SearchClient(appID: keys.appID, apiKey: keys.groupsKey)
    }
    
//    func performSearchForUsers(searchText: String) async -> Bool
//    {
//        do {
//            let users =  try await searchInUsersIndex(withQuery: searchText)
//            for user in users {
//                if user.nickname?.lowercased() == searchText.lowercased()
//                {
//                    return true
//                }
//            }
//        } catch {
//            print("error getting users from algolia: \(error)")
//        }
//        return false
//    }
//    
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
            for hit in searchResponse.hits
            {
                let groupID = hit.objectID
                let groupChat = try await FirebaseChatService.shared.fetchChat(withID: groupID)
                groups.append(groupChat)
            }
        }
        
        return groups
    }
    
    func checkIfUserWithNicknameExists(_ nickname: String) async -> Bool
    {
        do {
            // Create search request with FILTER for exact nickname match
            let searchRequest = SearchForHits(
                query: "",  // Empty query - we're filtering, not searching
                filters: "\(User.CodingKeys.nickname.rawValue):\(nickname)",  // Exact match on nickname field
                hitsPerPage: 1, typoTolerance: .searchTypoToleranceEnum(.false),
                indexName: "Users"  // We only need to know if it exists
            )
            
            // Perform search
            let response: SearchResponses<Hit> = try await usersClient.search(
                searchMethodParams: SearchMethodParams(
                    requests: [SearchQuery.searchForHits(searchRequest)]
                )
            )
            
            // Check if we got any results
            if let firstResult = response.results.first,
               case .searchResponse(let searchResponse) = firstResult
            {
                return searchResponse.nbHits ?? 0 > 0  // True if nickname exists
            }
            
        } catch {
            print("error getting users from algolia: \(error)")
        }
        return false
    }
}

struct AlgoliaSearchResult
{
    let users: [User]
    let groups: [Chat]
}
struct UserAlgolia: Codable {
    let objectID: String
    let nickname: String
    // add other fields stored in Algolia index
}
