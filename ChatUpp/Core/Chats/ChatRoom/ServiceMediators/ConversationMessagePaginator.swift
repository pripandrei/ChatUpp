//
//  ConversationMessagePaginator.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 7/17/25.
//
//
//import UIKit
//import Foundation
//
//actor ConversationMessagePaginator
//{
//    private var isNetworkPaginationRunning = false
//    
//    func paginateIfNeeded(ascending: Bool,
//                          viewModel: ChatRoomViewModel,
//                          updateHandler: @escaping (([IndexPath], IndexSet?) -> Void)) async
//    {
//        // Try local pagination first (always allowed) - must run on main thread
//        if let (newRows, newSections): ([IndexPath], IndexSet?) = await MainActor.run(body: {
//            viewModel.paginateAdditionalLocalMessages(ascending: ascending)
//        }) {
//            await MainActor.run {
//                updateHandler(newRows, newSections)
//                
//                if let startMessage = viewModel.lastPaginatedMessage
//                {
//                    viewModel.messageListenerService?.addListenerToExistingMessagesTest(
//                        startAtMesssage: startMessage,
//                        ascending: !ascending,
//                        limit: 30)
//                }
//            }
//            
//            return
//        }
//        
//        // Skip network pagination if already running
//        guard !isNetworkPaginationRunning else {
//            print("Network pagination already running, skipping")
//            return
//        }
//        
//        isNetworkPaginationRunning = true
//        
//        // Network pagination
//        do {
//            try await Task.sleep(for: .seconds(1))
//            
//            if let (newRows, newSections) = try await viewModel.handleAdditionalMessageClusterUpdate(inAscendingOrder: ascending) {
//                await MainActor.run {
//                    updateHandler(newRows, newSections)
//                    
//                    if ascending && viewModel.shouldAttachListenerToUpcomingMessages
//                    {
//                        viewModel.messageListenerService?.addListenerToUpcomingMessages()
//                    }
//                }
//            }
//        } catch {
//            print("Could not update conversation with additional messages: \(error)")
//        }
//        isNetworkPaginationRunning = false
//    }
//}
//
