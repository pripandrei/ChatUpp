import Foundation
import AlgoliaCore
import AlgoliaSearch

// Algolia-backed search is used only by dev builds.
// Prod builds use FirestoreSearchService (see ChatUpp/Search/).
#if DEV

final class AlgoliaSearchManager: SearchService
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
    
    func performSearch(_ searchText: String) async -> SearchResults? {
        do {
            let users = try await searchInUsersIndex(withQuery: searchText)
            let groups = try await searchInGroupsIndex(withQuery: searchText)
            return .init(users: users, groups: groups)
        } catch {
            print("Error while searching for index field: ", error)
            return nil
        }
    }
    
    func searchInUsersIndex(withQuery query: String) async throws -> [User]
    {
        // Create search request
        let searchRequest = SearchForHits(
            query: query,
            hitsPerPage: 20,
            typoTolerance: .searchTypoToleranceEnum(.false),
            indexName: "Users"
        )
        
        // Perform search - need to specify Hit type
        let response: SearchResponses<Hit> = try await usersClient.search(
            searchMethodParams: SearchMethodParams(
                requests: [SearchQuery.searchForHits(searchRequest)]
            )
        )

        if let firstResult = response.results.first,
           case .searchResponse(let searchResponse) = firstResult
        {
            return try await withThrowingTaskGroup(of: (Int, UncheckedSendableWrapper<User>)?.self) { group in
                for (index, hit) in searchResponse.hits.enumerated()
                {
                    let userID = hit.objectID
                    group.addTask { @MainActor in
                        do {
                            let user = try await FirestoreUserService.shared.getUserFromDB(userID: userID)
                            return (index, UncheckedSendableWrapper(object: user))
                        } catch let error as DecodingError {
                            print("Could not decode user with id \(userID): \(error)")
                            return nil
                        }
                    }
                }
                
                var results: [(index: Int, user: User)] = []
                
                for try await result in group {
                    if let (index, wrapper) = result {
                        results.append((index, wrapper.object))
                    }
                }
                
                return results.sorted { $0.index < $1.index }.map { $0.1 }
            }
        }
        return []
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
                do {
                    let groupChat = try await FirebaseChatService.shared.fetchChat(withID: groupID)
                    groups.append(groupChat)
                } catch {
                    print("Could not decode group chat with id \(groupID): \(error)")
                }
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
                hitsPerPage: 1,
                typoTolerance: .searchTypoToleranceEnum(.false),
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

#endif

