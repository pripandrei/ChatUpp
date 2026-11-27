//
//  FirestoreSearchService.swift
//  ChatUpp
//
//  Prod search implementation backed by Firestore Enterprise pipeline string
//  functions (toLower + startsWith/stringContains). Matches only the *start of
//  words*: every whitespace-separated search word must be a prefix of a word in
//  the name, e.g. "na" matches "Deli nadin lorenso" but not "Andrei".
//  https://firebase.google.com/docs/firestore/pipelines/functions/string-functions
//

import Foundation
import FirebaseFirestore

final class FirestoreSearchService: SearchService
{
    static let shared = FirestoreSearchService()
    
    private let db = Firestore.appDB
    
    private init() {}

    // See Footnote.swift [25]
    private func wordStartPrefixCondition(for searchTerm: String, in field: String) -> BooleanExpression
    {
        let searchWords = searchTerm.lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }

        let name = Field(field).toLower()
        let conditions = searchWords.map { word in
            name.startsWith(word) || name.stringContains(" \(word)")
        }

        guard let firstCondition = conditions.first else
        {
            return name.equal("")
        }
        return conditions.dropFirst().reduce(firstCondition) { $0 && $1 }
    }
    
    func performSearch(_ searchText: String) async -> SearchResults?
    {
        do
        {
            let users = try await searchInUsersIndex(withQuery: searchText)
            let groups = try await searchInGroupsIndex(withQuery: searchText)
            return .init(users: users, groups: groups)
        }
        catch
        {
            print("Error while searching in Firestore: ", error)
            return nil
        }
    }
    
    func searchInUsersIndex(withQuery query: String) async throws -> [User]
    {
        let searchTerm = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !searchTerm.isEmpty else { return [] }

        let snapshot = try await db.pipeline()
            .collection(FirestoreCollection.users.rawValue)
            .where(wordStartPrefixCondition(for: searchTerm, in: User.CodingKeys.name.rawValue))
            .limit(20)
            .execute()
        
        return try await withThrowingTaskGroup(of: User.self) { group in
            for result in snapshot.results
            {
                guard let userID = result.id else { continue }
                group.addTask {
                    try await FirestoreUserService.shared.getUserFromDB(userID: userID)
                }
            }
            return try await group.reduce(into: []) { $0.append($1) }
        }
    }
    
    private func searchInGroupsIndex(withQuery query: String) async throws -> [Chat]
    {
        let searchTerm = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !searchTerm.isEmpty else { return [] }

        let snapshot = try await db.pipeline()
            .collection(FirestoreCollection.chats.rawValue)
            .where(wordStartPrefixCondition(for: searchTerm, in: Chat.CodingKeys.name.rawValue))
            .limit(20)
            .execute()
        
        var groups: [Chat] = []
        for result in snapshot.results
        {
            guard let chatID = result.id else { continue }
            let groupChat = try await FirebaseChatService.shared.fetchChat(withID: chatID)
            groups.append(groupChat)
        }
        return groups
    }
    
    func checkIfUserWithNicknameExists(_ nickname: String) async -> Bool
    {
        do
        {
            let snapshot = try await db.collection(FirestoreCollection.users.rawValue)
                .whereField(User.CodingKeys.nickname.rawValue, isEqualTo: nickname)
                .limit(to: 1)
                .getDocuments()
            return !snapshot.isEmpty
        }
        catch
        {
            print("error checking nickname in Firestore: \(error)")
            return false
        }
    }
}
