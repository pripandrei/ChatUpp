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
    
    private(set) var isReachable: Bool = false
//    var onStatusChanged: ((Bool) -> Void)?
    var statusChanged = PassthroughSubject<Bool,Never>()
    
    private init()
    {
        self.startNetworkMonitor()
    }
    
    private func startNetworkMonitor()
    {
        monitor.pathUpdateHandler = { path in
            let isConected = path.status == .satisfied
            self.isReachable = isConected
            
            DispatchQueue.main.async {
                self.statusChanged.send(isConected)
            }
        }
        monitor.start(queue: networkQueue)
    }
}



//private func retryGroupCreationOnReconnect() async throws
//{
//    try await withCheckedThrowingContinuation { continuation in
//        NetworkMonitor.shared.statusChanged
//            .receive(on: DispatchQueue.main)
//            .prefix(1) // Only listen to the *first* reachable event
//            .filter { $0 }
//            .sink { [weak self] _ in
//                Task {
//                    do {
//                        try await self?.finishGroupCreation()
//                        continuation.resume()
//                    } catch {
//                        continuation.resume(throwing: error)
//                    }
//                }
//            }.store(in: &subscribtions)
//    }
//}
