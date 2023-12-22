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
    
    private init() {}
    
    func performSearch(_ searchText: String) async -> [AlgoliaResultData] {
        let text = Query(searchText)
        do {
            let settings = Settings().set(\.typoTolerance, to: false)
            try index.setSettings(settings)
            
            let result = try index.search(query: text)
            
            return result.hits.compactMap { hitJson in
                if let name = hitJson.object["name"]?.object() as? String,
                    let profileImage = hitJson.object["photo_url"]?.object() as? String
                {
                    return AlgoliaResultData(name: name, profileImageLink: profileImage)
                }
                return nil
            }
        } catch {
            print("Error while searching for index field: ", error)
        }
        return []
    }
}

struct AlgoliaResultData {
    let name: String
    let profileImageLink: String
}
