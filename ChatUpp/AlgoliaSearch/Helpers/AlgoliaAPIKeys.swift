//
//  AlgoliaAPIKeys.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/9/25.
//
import Foundation

struct AlgoliaAPIKeys
{
    let appID: String
    let usersKey: String
    let groupsKey: String
    
    static func load() -> AlgoliaAPIKeys?
    {
        guard let path = Bundle.main.path(forResource: "APIKeys", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let APP_ID = dict["ALGOLIA_APP_ID"] as? String,
              let API_KEY_USERS = dict["ALGOLIA_API_KEY_USERS"] as? String,
              let API_KEY_GROUPS = dict["ALGOLIA_API_KEY_GROUPS"] as? String,
              !APP_ID.isEmpty,
              !API_KEY_USERS.isEmpty,
              !API_KEY_GROUPS.isEmpty
        else {
            print("⚠️ Missing Algolia credentials — please configure APIKeys.plist")
            return nil
        }
        return .init(appID: APP_ID,
                     usersKey: API_KEY_USERS,
                     groupsKey: API_KEY_GROUPS)
    }
}
