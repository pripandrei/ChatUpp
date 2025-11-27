//
//  NetworkMonitor.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 6/12/25.
//

import Foundation
import Network
import Combine

final class NetworkMonitor
{
    static let shared = NetworkMonitor()
    
    private let monitor = NWPathMonitor()
    private let networkQueue = DispatchQueue(label: "NetworkMonitorQueue")
    
    @Published  var isReachable: Bool = false
    
    private init()
    {
        self.startNetworkMonitor()
    }
    
    private func startNetworkMonitor()
    {
        monitor.pathUpdateHandler = { path in
            let isConected = path.status == .satisfied
            self.isReachable = isConected
        }
        monitor.start(queue: networkQueue)
    }
}

