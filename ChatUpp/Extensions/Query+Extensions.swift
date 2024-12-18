//
//  Query+Extensions.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 8/22/24.
//

import Foundation
import FirebaseFirestore

extension Query 
{
    func getDocuments<T>(as type: T.Type) async throws -> [T] where T: Decodable
    {
        let referenceType = try await self.getDocuments()
        
        return referenceType.documents.compactMap { document in
            try? document.data(as: type.self)
        }
    }
}
