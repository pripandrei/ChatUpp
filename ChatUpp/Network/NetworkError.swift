//
//  NetworkError.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 6/12/25.
//

import Foundation

enum NetworkError: LocalizedError
{
    case timeout
    case noNetwork
    
    var errorDescription: String?
    {
        switch self
        {
        case .timeout: return "Request timed out, check network connection"
        case .noNetwork: return "No network connection"
        }
    }
}
