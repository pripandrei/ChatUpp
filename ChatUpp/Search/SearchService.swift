//
//  SearchService.swift
//  ChatUpp
//
//  Environment-agnostic search interface.
//  Dev builds search via Algolia, prod builds via Firestore Enterprise string matching.
//

import Foundation

struct SearchResults
{
    let users: [User]
    let groups: [Chat]
}

protocol SearchService
{
    func performSearch(_ searchText: String) async -> SearchResults?
    func searchInUsersIndex(withQuery query: String) async throws -> [User]
    func checkIfUserWithNicknameExists(_ nickname: String) async -> Bool
}

enum SearchServiceProvider
{
    static var shared: any SearchService
    {
        #if PROD
        return FirestoreSearchService.shared
        #else
        return AlgoliaSearchManager.shared
        #endif
    }
}
