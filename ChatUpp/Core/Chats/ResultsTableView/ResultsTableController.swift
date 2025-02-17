//
//  ResultsTableController.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 11/8/23.
//

import UIKit
import SkeletonView

enum SkeletonAnimationState {
    case initiated
    case terminated
    case none
}

final class ResultsTableController: UITableViewController {
    
    enum UsersSearch {
        case local
        case global
    }
    
    weak var coordinatorDelegate: Coordinator?
    
    var searchBar: UISearchBar?
    
    var filteredUsers: [ResultsCellViewModel] = [] 
    var userSearch: UsersSearch!
    private var noUserWasFoundLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
        configureTextLabel()
    }
   
    private func configureTextLabel() {
        tableView.addSubview(noUserWasFoundLabel)
        
        noUserWasFoundLabel.isHidden = true
        noUserWasFoundLabel.text = "No user's have been found"
        noUserWasFoundLabel.textColor = #colorLiteral(red: 0.547631681, green: 0.7303310037, blue: 0.989274919, alpha: 1)
        noUserWasFoundLabel.sizeToFit()
        
        noUserWasFoundLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            noUserWasFoundLabel.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            noUserWasFoundLabel.centerYAnchor.constraint(equalTo: tableView.centerYAnchor, constant: -100),
        ])
    }
    
    func toggleSkeletonAnimation(_ value: SkeletonAnimationState) {
        if value == .initiated {
            initiateSkeletonAnimation()
        } else {
            terminateSkeletonAnimation()
        }
    }

    private func initiateSkeletonAnimation() {
        let skeletonAnimationColor = #colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 1)
        let skeletonItemColor = #colorLiteral(red: 0.4780891538, green: 0.7549679875, blue: 0.8415568471, alpha: 1)
        tableView.showAnimatedGradientSkeleton(usingGradient: .init(baseColor: skeletonItemColor, secondaryColor: skeletonAnimationColor))
        noUserWasFoundLabel.isHidden = true
    }
    
    private func terminateSkeletonAnimation() {
        tableView.stopSkeletonAnimation()
        tableView.hideSkeleton(transition: .crossDissolve(0.25))
        noUserWasFoundLabel.isHidden = false
    }
    
    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ResultsTableCell.self, forCellReuseIdentifier: ReuseIdentifire.SearchRusultsTableCell.searchResult.identifire)
        tableView.sectionHeaderTopPadding = 0
        tableView.rowHeight = 55
        tableView.backgroundColor = #colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 1)
        tableView.isSkeletonable = true
        
        // Omit tableView to automatically go behind navigation bar
        // when Skeleton view is running
        edgesForExtendedLayout = []
    }
}

//MARK: - SKELETON TABLE VIEW DATA SOURCE

extension ResultsTableController: SkeletonTableViewDataSource {
    func collectionSkeletonView(_ skeletonView: UITableView, cellIdentifierForRowAt indexPath: IndexPath) -> ReusableCellIdentifier {
       return ReuseIdentifire.SearchRusultsTableCell.searchResult.identifire
    }
}

//MARK: - TABLE VIEW DATASOURCE
extension ResultsTableController {

    override func numberOfSections(in tableView: UITableView) -> Int {
        if !filteredUsers.isEmpty {
            return 1
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredUsers.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifire.SearchRusultsTableCell.searchResult.identifire,
                                                       for: indexPath) as? ResultsTableCell
        else {fatalError("Could not dequeue Results cell")}
        
        cell.configure(viewModel: filteredUsers[indexPath.item])
        noUserWasFoundLabel.isHidden = true
        
        return cell
    }
}

//MARK: - TABLE VIEW DELEGATE
extension ResultsTableController
{
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard !tableView.sk.isSkeletonActive else {return nil}
        
        let tableViewHeaderFooterView = UITableViewHeaderFooterView()
        var configuration = UIListContentConfiguration.subtitleCell()
        
        if userSearch == .local {
            configuration.text = "Chats".uppercased()
        } else {
            configuration.text = "Global search".uppercased()
        }
        
        configuration.textProperties.color = .white
        configuration.textProperties.font = UIFont(name: "HelveticaNeue", size: 13)!
        
        tableViewHeaderFooterView.contentConfiguration = configuration
        tableViewHeaderFooterView.contentView.backgroundColor = #colorLiteral(red: 0.1177659705, green: 0.3260737062, blue: 0.4667393565, alpha: 1)
        
        return tableViewHeaderFooterView
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 24
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        
        searchBar?.resignFirstResponder()
        
        Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { _ in
            let user = self.filteredUsers[indexPath.item].participant
            var conversationViewModel: ChatRoomViewModel!
        
            defer {
                self.coordinatorDelegate?.openConversationVC(conversationViewModel: conversationViewModel)
            }

            if let existingChat = self.filteredUsers[indexPath.item].chat {
                conversationViewModel = ChatRoomViewModel(conversation: existingChat)
            } else {
                conversationViewModel = ChatRoomViewModel(participant: user)
            }
//            else if let authUser = try? AuthenticationManager.shared.getAuthenticatedUser() {
//                let participants = [
//                    ChatParticipant(userID: authUser.uid, unseenMessageCount: 0),
//                    ChatParticipant(userID: user.id, unseenMessageCount: 0)
//                ]
//                let newChat = ChatRoomViewModel.createChat(with: participants)
//                conversationViewModel = ChatRoomViewModel(conversation: newChat)
//            }
        }
    }
}






//
//
//
//
//// MARK: - Conversation Initialization
//extension ChatRoomViewModel {
//    private enum ConversationError: Error {
//        case noMessages
//        case fetchError(Error)
//        case avatarError(Error)
//    }
//    
//    private func initiateConversation() async {
//        do {
//            conversationInitializationStatus = .inProgress
//            
//            if shouldFetchNewMessages {
//                try await initializeWithRemoteData()
//            } else {
//                try initializeWithLocalData()
//            }
//            
//            conversationInitializationStatus = .finished
//        } catch {
//            conversationInitializationStatus = .failed
//            handleError(error)
//        }
//    }
//    
//    private func initializeWithRemoteData() async throws {
//        let messages = try await fetchConversationMessages()
//        
//        if conversation?.isGroup == true {
//            try await syncGroupUsers(for: messages)
//        }
//        
//        await realmService?.addMessagesToConversationInRealm(messages)
//        try initializeWithLocalData()
//    }
//    
//    private func initializeWithLocalData() throws {
//        guard var messages = conversation?.getMessages(),
//              !messages.isEmpty else {
//            throw ConversationError.noMessages
//        }
//        
//        if !shouldDisplayLastMessage {
//            messages.removeFirst()
//        }
//        
//        createMessageClustersWith(messages)
//    }
//    
//    // MARK: - Group Chat Handling
//    
//    private func syncGroupUsers(for messages: [Message]) async throws {
//        let missingUserIDs = findMissingUserIDs(from: messages)
//        
//        guard !missingUserIDs.isEmpty else { return }
//        
//        let users = try await fetchAndStoreUsers(with: missingUserIDs)
//        try await fetchAndCacheAvatars(for: users)
//    }
//    
//    private func findMissingUserIDs(from messages: [Message]) -> [String] {
//        let senderIDs = Set(messages.map(\.senderId))
//        let existingUsers = fetchExistingUsers(with: senderIDs)
//        let existingUserIds = Set(existingUsers.map(\.id))
//        
//        return Array(senderIDs.subtracting(existingUserIds))
//    }
//    
//    private func fetchExistingUsers(with senderIDs: Set<String>) -> [User] {
//        let filter = NSPredicate(format: "id IN %@", Array(senderIDs))
//        return RealmDataBase.shared.retrieveObjects(ofType: User.self, filter: filter)?.toArray() ?? []
//    }
//    
//    private func fetchAndStoreUsers(with userIDs: [String]) async throws -> [User] {
//        let users = try await FirestoreUserService.shared.fetchUsers(with: userIDs)
//        RealmDataBase.shared.add(objects: users)
//        return users
//    }
//    
//    // MARK: - Avatar Handling
//    
//    private func fetchAndCacheAvatars(for users: [User]) async throws {
//        try await withThrowingTaskGroup(of: Void.self) { group in
//            for user in users {
//                group.addTask {
//                    try await self.fetchAndCacheAvatar(for: user)
//                }
//            }
//            try await group.waitForAll()
//        }
//    }
//    
//    private func fetchAndCacheAvatar(for user: User) async throws {
//        guard var avatarURL = user.photoUrl else { return }
//        
//        avatarURL = avatarURL.replacingOccurrences(of: ".jpg", with: "_small.jpg")
//        
//        do {
//            let imageData = try await FirebaseStorageManager.shared.getImage(
//                from: .user(user.id),
//                imagePath: avatarURL
//            )
//            CacheManager.shared.saveImageData(imageData, toPath: avatarURL)
//        } catch {
//            throw ConversationError.avatarError(error)
//        }
//    }
//    
//    // MARK: - Error Handling
//    
//    private func handleError(_ error: Error) {
//        let errorMessage: String
//        
//        switch error {
//        case ConversationError.noMessages:
//            errorMessage = "No messages found in conversation"
//        case ConversationError.fetchError(let underlyingError):
//            errorMessage = "Failed to fetch conversation: \(underlyingError.localizedDescription)"
//        case ConversationError.avatarError(let underlyingError):
//            errorMessage = "Failed to fetch avatar: \(underlyingError.localizedDescription)"
//        default:
//            errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
//        }
//        
//        Logger.error(errorMessage)
//    }
//}
