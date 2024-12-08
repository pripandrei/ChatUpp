//
//  ChatsManager.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/2/23.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift
import Combine


typealias Listener = ListenerRegistration

struct ChatUpdate<T> {
    let data: T
    let changeType: DocumentChangeType
}

final class FirebaseChatService {

    static let shared = FirebaseChatService()
    
    private init() {}
    
    private let firestoreEncoder = Firestore.Encoder()
    private let firestoreDecoder = Firestore.Decoder()
    
    private let db = Firestore.firestore()
    
    private lazy var chatsCollection = db.collection(FirestoreCollection.chats.rawValue)
    
    private func chatDocument(documentPath: String) -> DocumentReference {
        return chatsCollection.document(documentPath)
    }
    
    func createNewChat(chat: Chat) async throws {
        try chatDocument(documentPath: chat.id).setData(from: chat, merge: false)
    }

    //TODO: - modify function to adjusts current participants map strucutre
    /// - Replace deleted user id in chats
    func replaceUserId(_ id: String, with deletedId: String) async throws {
        let chatsQuery = try await chatsCollection.whereField(FirestoreField.participants.rawValue, arrayContainsAny: [id]).getDocuments()
        
        for document in chatsQuery.documents {
            try await document.reference.updateData([Chat.CodingKeys.participants.rawValue: FieldValue.arrayRemove([id])])
            try await document.reference.updateData([Chat.CodingKeys.participants.rawValue: FieldValue.arrayUnion([deletedId])])
        }
    }
}

//MARK: - fetch chats
extension FirebaseChatService {
    func fetchChats(containingUserID userID: String) async throws -> [Chat] {
        return try await chatsCollection.whereField(Chat.CodingKeys.participants.rawValue, arrayContainsAny: [userID]).getDocuments(as: Chat.self)
    }
}

//MARK: - remove chat
extension FirebaseChatService 
{
    func removeChat(chatID: String) async throws {
//        try await removeSubcollection(inChatWithID: chatID)
        try await deleteSubcollection(fromChatWithID: chatID)
        try await chatsCollection.document(chatID).delete()
    }
    
    func deleteSubcollection(fromChatWithID chatID: String) async throws
    {
        var batch: WriteBatch
        var documents: [QueryDocumentSnapshot]
        
        repeat {
            documents = try await chatDocument(documentPath: chatID)
                .collection(FirestoreCollection.messages.rawValue)
                .getDocuments()
                .documents
            
            batch = Firestore.firestore().batch()
            
            for document in documents {
                batch.deleteDocument(document.reference)
            }
            
            try await batch.commit()
        } while !documents.isEmpty
    }

}

//MARK: - Create and remove message

extension FirebaseChatService
{
    @MainActor
    func createMessage(message: Message, atChatPath path: String) async throws {
        try getMessageDocument(messagePath: message.id, fromChatDocumentPath: path).setData(from: message.self, merge: false)
    }
    func removeMessage(messageID: String, conversationID: String) async throws {
        try await getMessageDocument(messagePath: messageID, fromChatDocumentPath: conversationID).delete()
    }
}


//MARK: - Fetch messages

extension FirebaseChatService
{
    func getMessagesCount(fromChatDocumentPath documentPath: String) async throws -> Int  {
        let countQuery = chatDocument(documentPath: documentPath).collection(FirestoreCollection.messages.rawValue).count
        let count = try await countQuery.getAggregation(source: .server).count
        return count.intValue
    }
    
    func getMessageDocument(messagePath: String, fromChatDocumentPath documentPath: String) -> DocumentReference {
        return chatDocument(documentPath: documentPath).collection(FirestoreCollection.messages.rawValue).document(messagePath)
    }
    
    func getAllMessages(fromChatDocumentPath documentID: String) async throws -> [Message] {
        let messagesReference = chatDocument(documentPath: documentID).collection(FirestoreCollection.messages.rawValue)
        return try await messagesReference.order(by: Message.CodingKeys.timestamp.rawValue, descending: false).getDocuments(as: Message.self)
    }
    
    func getUnreadMessagesCount(from chatID: String, whereMessageSenderID senderID: String) async throws -> Int {
        let messagesReference = chatDocument(documentPath: chatID).collection(FirestoreCollection.messages.rawValue)
        return try await messagesReference.whereField(Message.CodingKeys.messageSeen.rawValue, isEqualTo: false).whereField(Message.CodingKeys.senderId.rawValue, isEqualTo: senderID).getDocuments().count
    }
    
    func getFirstUnseenMessage(fromChatDocumentPath documentID: String, whereSenderIDNotEqualTo senderID: String) async throws -> Message?
    {
        let messagesReference = chatDocument(documentPath: documentID).collection(FirestoreCollection.messages.rawValue)
        return try await messagesReference
            .whereField(Message.CodingKeys.messageSeen.rawValue, isEqualTo: false)
            .whereField(Message.CodingKeys.senderId.rawValue, isNotEqualTo: senderID)
            .order(by: Message.CodingKeys.timestamp.rawValue, descending: false)
            .limit(to: 1)
            .getDocuments(as: Message.self)
            .first
    }
    
    @MainActor
    func getRecentMessage(from chat: Chat) async throws -> Message?
    {
        guard let recentMessageID = chat.recentMessageID else {return nil}
        do {
            let message = try await getMessageDocument(messagePath: recentMessageID, fromChatDocumentPath: chat.id).getDocument(as: Message.self)
            return message
        } catch {
            
            print("Error fetching recent message: ", error.localizedDescription)
            return nil
        }
    }
}

//MARK: - Update messages

extension FirebaseChatService
{
    func updateMessageText(_ messageText: String, messageID: String, chatID: String) async throws {
        let data: [String: Any] = [
            Message.CodingKeys.messageBody.rawValue : messageText,
            Message.CodingKeys.isEdited.rawValue : true
        ]
        try await getMessageDocument(messagePath: messageID, fromChatDocumentPath: chatID).updateData(data)
    }
    
    func updateMessageSeenStatus(messageID: String , chatID: String) async throws {
        let data: [String: Any] = [
            Message.CodingKeys.messageSeen.rawValue : true
        ]
        try await getMessageDocument(messagePath: messageID, fromChatDocumentPath: chatID).updateData(data)
    }
    
    func updateChatRecentMessage(recentMessageID: String ,chatID: String) async throws {
        let data: [String: Any] = [
            Chat.CodingKeys.recentMessageID.rawValue : recentMessageID
        ]
        try await chatDocument(documentPath: chatID).updateData(data)
    }

    func updateMessageImagePath(messageID: String, chatDocumentPath: String, path: String) async throws {
        let data: [String: Any] = [
            Message.CodingKeys.imagePath.rawValue: path
        ]
        try await getMessageDocument(messagePath: messageID, fromChatDocumentPath: chatDocumentPath).updateData(data)
    }

    func updateMessageImageSize(messageID: String, chatDocumentPath: String, imageSize: MessageImageSize) async throws {
        let encodedImageSize = try firestoreEncoder.encode(imageSize)
        
        let data: [String: Any] = [
            Message.CodingKeys.imageSize.rawValue: encodedImageSize
        ]
        try await getMessageDocument(messagePath: messageID, fromChatDocumentPath: chatDocumentPath).updateData(data)
    }
}

//MARK: - update chat participants

extension FirebaseChatService
{
    func updateUnreadMessageCount(for participantID: String, inChatWithID chatID: String, increment: Bool) async throws
    {
        let fieldPath = "participants.\(participantID).\(ChatParticipant.CodingKeys.unseenMessagesCount.rawValue)"
        
        let counterValue = increment ? +1 : -1
        let data = [fieldPath : FieldValue.increment(Int64(counterValue))]
        
        try await chatDocument(documentPath: chatID).updateData(data)
    }
    
    func removeParticipant(participantID: String, inChatWithID chatID: String) async throws
    {
        let isDeletedField = "participants.\(participantID).is_deleted"
//        try await chatsCollection.document(chatID).updateData( [isDeletedField: true] )
        try await chatDocument(documentPath: chatID).updateData( [isDeletedField: true] )
    }
}


//MARK: - Listeners

extension FirebaseChatService 
{
    func chatsPublisher(containingParticipantUserID participantUserID: String) -> AnyPublisher<ChatUpdate<Chat>, Never>
    {
        let subject = PassthroughSubject<ChatUpdate<Chat>, Never>()
        
        chatsCollection
            .whereField("participants.\(participantUserID).is_deleted", isEqualTo: false)
            .addSnapshotListener { snapshot, error in
                guard error == nil else { print(error!.localizedDescription); return }
                
                snapshot?.documentChanges.forEach { change in
                    if let chat = try? change.document.data(as: Chat.self) {
                        let update = ChatUpdate(data: chat, changeType: change.type)
                        subject.send(update)
                    }
                }
            }
        return subject.eraseToAnyPublisher()
    }
    
    // messages listners
    func addListenerForUpcomingMessages(inChat chatID: String,
                                        startingAfterMessage messageID: String,
                                        onNewMessageReceived:  @escaping (Message, DocumentChangeType) -> Void) async throws -> Listener
    {
        let document = try await chatsCollection.document(chatID)
            .collection(FirestoreCollection.messages.rawValue)
            .document(messageID)
            .getDocument()
        
        return chatDocument(documentPath: chatID)
            .collection(FirestoreCollection.messages.rawValue)
            .order(by: Message.CodingKeys.timestamp.rawValue, descending: false)
            .start(afterDocument: document)
            .addSnapshotListener { snapshot, error in
                guard error == nil else { print(error!.localizedDescription); return }
                guard let documents = snapshot?.documentChanges else { print("No Message Documents to listen"); return }
                
                for document in documents {
                    guard let message = try? document.document.data(as: Message.self) else { continue }
                    onNewMessageReceived(message, document.type)
                }
                
            }
    }
    
    func addListenerForExistingMessages(inChat chatID: String,
                                        startAtTimestamp startTimestamp: Date,
                                        ascending: Bool,
                                        limit: Int,
                                        onMessageUpdated: @escaping (Message, DocumentChangeType) -> Void) -> Listener
    {
        
        return chatDocument(documentPath: chatID)
            .collection(FirestoreCollection.messages.rawValue)
            .order(by: Message.CodingKeys.timestamp.rawValue, descending: !ascending)
            .start(at: [startTimestamp])
            .limit(to: limit)
            .addSnapshotListener { snapshot, error in
                guard error == nil else { print(error!.localizedDescription); return }
                guard let documents = snapshot?.documentChanges else { print("No Message Documents to listen"); return }
                
                for document in documents {
                    guard let message = try? document.document.data(as: Message.self) else { continue }
                    onMessageUpdated(message, document.type)
                }
            }
    }
}

//MARK: - Pagination fetch

extension FirebaseChatService 
{
    func fetchMessagesFromChat(chatID: String,
                               startingFrom messageID: String?,
                               inclusive: Bool,
                               fetchDirection: MessagesFetchDirection,
                               limit: Int = 80) async throws -> [Message]
    {
        var query: Query = chatDocument(documentPath: chatID).collection(FirestoreCollection.messages.rawValue)

        if fetchDirection == .ascending {
            query = query.order(by: Message.CodingKeys.timestamp.rawValue, descending: false) // ascending order
        }
        else if fetchDirection == .descending {
            query = query.order(by: Message.CodingKeys.timestamp.rawValue, descending: true) // descending order
        }
        
        // if message is nil, it means that DB has only unseen messages
        // and we should just fetch them starting from first one
        if let messageID = messageID
        {
            let document = try await chatDocument(documentPath: chatID)
                .collection(FirestoreCollection.messages.rawValue)
                .document(messageID)
                .getDocument()
            
            if document.exists {
                query = inclusive ? query.start(atDocument: document) : query.start(afterDocument: document)
            }
        }
        
        return try await query.limit(to: limit)
            .getDocuments(as: Message.self)
    }
}

//MARK: Testing functions
extension FirebaseChatService {
    
    static func cleanFirestoreCache() async throws {
        do {
            try await Firestore.firestore().clearPersistence()
            print("Firestore cache successfully cleared")
        } catch {
            print("Error clearing Firestore cache: \(error.localizedDescription)")
        }
    }
    
    //MARK: - DELETE MESSAGES BY TIMESTAMP
    func testDeleteLastDocuments(documentPath: String) {
        chatDocument(documentPath: documentPath).collection(FirestoreCollection.messages.rawValue).order(by: Message.CodingKeys.timestamp.rawValue, descending: true)
            .limit(to: 1) // Limit the query to retrieve the last 10 documents
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Error fetching documents: \(error)")
                } else {
                    // Iterate through the documents and delete them
                    for document in querySnapshot!.documents {
                        document.reference.delete { error in
                            if error == nil {
                                print("Document \(document.documentID) successfully deleted")
                            }
                        }
                    }
                }
            }
    }
    
    /// For testing purposes only
    func updateAllMessagesFields() {
        
        // Query the "Chats" collection
        chatsCollection.getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error getting documents: \(error)")
            } else {
                guard let querySnapshot = querySnapshot else { return }
                
                for document in querySnapshot.documents {
                    let chatID = document.documentID
                    
                    // Reference to the "Messages" subcollection within the current chat
                    let messagesCollectionRef = self.chatsCollection.document(chatID).collection("messages")
                    
                    // Update the "is_edited" field for each document in the "Messages" subcollection
                    messagesCollectionRef.getDocuments { (messageQuerySnapshot, error) in
                        if let error = error {
                            print("Error getting documents: \(error)")
                        } else {
                            guard let messageQuerySnapshot = messageQuerySnapshot else { return }
                            
                            for messageDocument in messageQuerySnapshot.documents {
                                let messageID = messageDocument.documentID
                                
                                // Update the "is_edited" field for each message document
                                let messageDocRef = messagesCollectionRef.document(messageID)
                                messageDocRef.updateData(["is_edited": false]) { error in
                                    if let error = error {
                                        print("Error updating document: \(error)")
                                    } else {
                                        print("Document \(messageID) updated successfully")
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func testUpdateEditedFiled() {
        let data: [String: Any] = [
            Message.CodingKeys.isEdited.rawValue : false
        ]
        chatDocument(documentPath: "06067529-2DA4-48E0-9D8A-03305FF1AC8C").collection(FirestoreCollection.messages.rawValue).getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error fetching documents: \(error)")
            } else {
                // Iterate through the documents and delete them
                for document in querySnapshot!.documents {
                    document.reference.updateData(data)
                }
            }
        }
    }
    
    func migrateParticipantsField() 
    {
        chatsCollection.getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching chat documents: \(error)")
                return
            }
            
            guard let documents = snapshot?.documents else { return }
            
            let batch = self.db.batch()
            
            for document in documents {
                let chatId = document.documentID
                print(chatId)
//                if chatId == "543CFF01-4AA8-47FB-9965-9D1B0F75D460" {
                    // Fetch current participants array
                    if let oldParticipants = document.data()["participants"] as? [String: [String: Any]] {
                        // Prepare the new participants map
                        var newParticipantsMap: [String: [String: Any]] = [:]
                        
                        for participant in oldParticipants.values {
                            guard let userID = participant["user_id"] as? String else {
                                print("could not create participant")
                                continue
                            }
//                            values["user_id"]
                            newParticipantsMap[userID] = [
                                "user_id": userID,
                                "unseen_messages_count": 0,
                                "is_deleted": false
                            ]
                        }
                        
                        // Update chat document with new schema
                        let chatRef = self.chatsCollection.document(chatId)
                        
                        batch.updateData([
                            "participants": newParticipantsMap,
                            "participants_user_ids": FieldValue.delete() // Remove the field
                        ], forDocument: chatRef)
                    } else {
                        print("No participants array found for chat \(chatId)")
                    }
                    
//                    self.updateMessageSeenStatusToTrue(fromChatWithID: chatId)
//                }
            }
            
            // Commit the batch updates
            batch.commit { error in
                if let error = error {
                    print("Error updating chats: \(error)")
                } else {
                    print("Successfully updated chats")
                }
            }
        }
    }

    
    func updateMessageSeenStatusToTrue(fromChatWithID chatID: String) {
        let messagesCollection = self.chatsCollection.document(chatID).collection(FirestoreCollection.messages.rawValue)

        messagesCollection.whereField("message_seen", isEqualTo: false).getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching messages: \(error)")
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("No messages found.")
                return
            }
            
            let batch = self.db.batch()
            
            for document in documents {
                let documentRef = messagesCollection.document(document.documentID)
                batch.updateData(["message_seen": true], forDocument: documentRef)
            }
            
            // Commit the batch
            batch.commit { error in
                if let error = error {
                    print("Error updating messages: \(error)")
                } else {
                    print("Successfully updated all unseen messages to seen.")
                }
            }
        }

    }
}

//
////
////  CustomCollectionViewCell.swift
////  ChatUpp
////
////  Created by Andrei Pripa on 10/11/23.
////
//
//import UIKit
//import YYText
//import Combine
//import SkeletonView
//
//final class ConversationTableViewCell: UITableViewCell
//{
//    private var messageContainerLeadingConstraint: NSLayoutConstraint!
//    private var messageContainerTrailingConstraint: NSLayoutConstraint!
//    private var messageLabelTopConstraints: NSLayoutConstraint!
//    
//    private var messageImage: UIImage?
//    private var replyMessageLabel: ReplyMessageLabel = ReplyMessageLabel()
//    private var timeStamp = YYLabel()
//    private var subscribers = Set<AnyCancellable>()
//    
//    private(set) var messageBubbleContainer = UIView()
//    private(set) var messageLabel = YYLabel()
//    private(set) var seenStatusMark = YYLabel()
//    private(set) var editedLabel: UILabel?
//    private(set) var cellViewModel: ConversationCellViewModel!
//
//    private let cellSpacing = 3.0
//    private var messageSide: MessageSide!
//    private var maxMessageWidth: CGFloat {
//        return 292.0
//    }
//    
//    //MARK: - LIFECYCLE
//    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
//        super.init(style: style, reuseIdentifier: reuseIdentifier)
//
//        // Invert cell upside down
//        transform = CGAffineTransform(scaleX: 1, y: -1)
//        
//        backgroundColor = #colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 1)
//        setupBackgroundSelectionView()
//        setupMessageBubbleContainer()
//        setupMessageTextLabel()
//        setupSeenStatusMark()
//        setupTimestamp()
//    }
//    
//    // implement for proper cell selection highlight when using UIMenuContextConfiguration on tableView
//    private func setupBackgroundSelectionView()
//    {
//        let selectedView = UIView()
//        selectedView.backgroundColor = UIColor.clear
//        selectedBackgroundView = selectedView
//    }
//    
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    //MARK: - binding
//    private func setupBinding()
//    {
//        cellViewModel.$imageData
//            .receive(on: DispatchQueue.main)
//            .sink(receiveValue: { [weak self] data in
//                guard let data = data else {return}
//                if data == self?.cellViewModel.imageData {
//                    self?.configureImageAttachment(data: data)
//                }
//            }).store(in: &subscribers)
//    }
//
//    //MARK: - CELL PREPARE CLEANUP
//    private func cleanupCellContent()
//    {
//        messageLabel.attributedText = nil
//        timeStamp.text = nil
//        timeStamp.backgroundColor = .clear
//        messageImage = nil
//        seenStatusMark.attributedText = nil
//        timeStamp.textContainerInset = .zero
//        editedLabel?.text = nil
//        replyMessageLabel.removeFromSuperview()
//        setMessagePadding(.initial)
//        
//        // Layout with no animation to hide resizing animation of cells on keyboard show/hide
//        // or any other table view content offset change
//        UIView.performWithoutAnimation {
//            self.contentView.layoutIfNeeded()
//        }
//    }
//    
//    //MARK: - CELL DATA CONFIGURATION
//    func configureCell(usingViewModel viewModel: ConversationCellViewModel, forSide side: MessageSide) {
//        
//        self.cleanupCellContent()
//        
//        self.cellViewModel = viewModel
//        self.messageSide = side
//        
//        self.timeStamp.text = viewModel.timestamp
//        self.setupReplyMessage()
//        self.setupEditedLabel()
//        self.setupBinding()
//        self.adjustMessageSide()
//
//        if viewModel.cellMessage?.messageBody != "" {
//            self.messageLabel.attributedText = self.makeAttributedStringForMessage()
//            self.handleMessageBubbleLayout()
//            return
//        }
//        configureImageAttachment(data: viewModel.imageData)
//    }
//    
//    private func configureMessageSeenStatus()
//    {
//        guard let message = cellViewModel.cellMessage else {return}
//        let iconSize = message.messageSeen ? CGSize(width: 15, height: 14) : CGSize(width: 16, height: 12)
//        let seenStatusIcon = message.messageSeen ? SeenStatusIcon.double.rawValue : SeenStatusIcon.single.rawValue
//        guard let seenStatusIconImage = UIImage(named: seenStatusIcon)?.resize(to: iconSize) else {return}
//
//        let imageAttributedString = NSMutableAttributedString.yy_attachmentString(withContent: seenStatusIconImage, contentMode: .center, attachmentSize: seenStatusIconImage.size, alignTo: UIFont(name: "Helvetica", size: 4)!, alignment: .center)
//      
//        seenStatusMark.attributedText = imageAttributedString
//    }
//    
//    private func makeAttributedStringForMessage() -> NSAttributedString?
//    {
//        guard let message = cellViewModel.cellMessage else {return nil}
//        
//        let attributes: [NSAttributedString.Key : Any] =
//        [
//            .font: UIFont(name: "Helvetica", size: 17)!,
//            .foregroundColor: UIColor.white,
//            .paragraphStyle: {
//                let paragraphStyle = NSMutableParagraphStyle()
//                paragraphStyle.alignment = .left
//                paragraphStyle.lineBreakMode = .byWordWrapping
//                return paragraphStyle
//            }()
//        ]
//        return NSAttributedString(string: message.messageBody, attributes: attributes)
//    }
//    
//// MARK: - UI INITIAL STEUP
//    
//    private func setupEditedLabel()
//    {
//        guard let message = cellViewModel.cellMessage else {return}
//        
//        if message.isEdited
//        {
//            editedLabel = UILabel()
//        
//            messageLabel.addSubviews(editedLabel!)
//            
//            editedLabel!.font = UIFont(name: "TimesNewRomanPSMT", size: 13)
//            editedLabel!.text = "edited"
//            editedLabel!.textColor = #colorLiteral(red: 0.74693048, green: 0.7898075581, blue: 1, alpha: 1)
//            editedLabel!.translatesAutoresizingMaskIntoConstraints = false
//            
//            NSLayoutConstraint.activate([
//                editedLabel!.trailingAnchor.constraint(equalTo: timeStamp.leadingAnchor, constant: -2),
//                editedLabel!.bottomAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: -5)
//            ])
//        }
//    }
//    
//    private func setupSeenStatusMark() {
//        messageLabel.addSubview(seenStatusMark)
//        
//        seenStatusMark.font = UIFont(name: "Helvetica", size: 4)
//        seenStatusMark.translatesAutoresizingMaskIntoConstraints = false
//        
//        NSLayoutConstraint.activate([
//            seenStatusMark.trailingAnchor.constraint(equalTo: messageLabel.trailingAnchor, constant: -8),
//            seenStatusMark.bottomAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: -5)
//        ])
//    }
//    
//    private func setupTimestamp() {
//        messageLabel.addSubview(timeStamp)
//        
//        timeStamp.font = UIFont(name: "TimesNewRomanPSMT", size: 13)
//        timeStamp.layer.cornerRadius = 7
//        timeStamp.clipsToBounds = true
//        timeStamp.textColor = #colorLiteral(red: 0.74693048, green: 0.7898075581, blue: 1, alpha: 1)
//        timeStamp.translatesAutoresizingMaskIntoConstraints = false
//        
//        NSLayoutConstraint.activate([
//            timeStamp.trailingAnchor.constraint(equalTo: seenStatusMark.leadingAnchor, constant: -2),
//            timeStamp.bottomAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: -5)
//        ])
//    }
//    
//    private func setupTimestampBackgroundForImage() {
//        timeStamp.backgroundColor = .darkGray.withAlphaComponent(0.6)
//        timeStamp.textContainerInset = UIEdgeInsets(top: 2, left: 6, bottom: 2, right: 6)
//    }
//    
//    private func setupMessageTextLabel() {
//        messageLabel.numberOfLines = 0
//        messageLabel.preferredMaxLayoutWidth = maxMessageWidth
//        messageLabel.contentMode = .redraw
//        messageLabel.layer.cornerRadius = 15
//        messageLabel.clipsToBounds = true
//        
//        messageLabel.translatesAutoresizingMaskIntoConstraints = false
//
//        NSLayoutConstraint.activate([
////            messageLabel.topAnchor.constraint(equalTo: replyMessageLabel.bottomAnchor),
//            messageLabel.bottomAnchor.constraint(equalTo: messageBubbleContainer.bottomAnchor),
//            messageLabel.leadingAnchor.constraint(equalTo: messageBubbleContainer.leadingAnchor),
//            messageLabel.trailingAnchor.constraint(equalTo: messageBubbleContainer.trailingAnchor),
//        ])
//    }
//}
//
//// MARK: - MESSAGE BUBBLE LAYOUT HANDLER
//extension ConversationTableViewCell
//{
//    func handleMessageBubbleLayout()
//    {
//        createMessageTextLayout()
//        let padding = getMessagePaddingStrategy()
//        setMessagePadding(padding)
////        adjustMessageLabelPadding()
//    }
//    
//    func createMessageTextLayout() {
//        let textLayout = YYTextLayout(containerSize: CGSize(width: messageLabel.intrinsicContentSize.width, height: messageLabel.intrinsicContentSize.height), text: messageLabel.attributedText!)
//        messageLabel.textLayout = textLayout
//        setMessagePadding(.initial)
//    }
//    
//    // MARK: - MESSAGE BUBBLE CONSTRAINTS
//    func adjustMessageSide() {
//        if messageContainerLeadingConstraint != nil { messageContainerLeadingConstraint.isActive = false }
//        if messageContainerTrailingConstraint != nil { messageContainerTrailingConstraint.isActive = false }
//
//        switch messageSide {
//        case .right:
//            configureMessageSeenStatus()
//            
//            messageContainerLeadingConstraint = messageBubbleContainer.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor)
//            messageContainerTrailingConstraint = messageBubbleContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10)
//            messageContainerLeadingConstraint.isActive = true
//            messageContainerTrailingConstraint.isActive = true
//            messageBubbleContainer.backgroundColor = #colorLiteral(red: 0.7171613574, green: 0.4463854432, blue: 0.351280123, alpha: 1)
//        case .left:
//            messageContainerLeadingConstraint = messageBubbleContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10)
//            messageContainerTrailingConstraint = messageBubbleContainer.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor)
//            messageContainerLeadingConstraint.isActive = true
//            messageContainerTrailingConstraint.isActive = true
//            messageBubbleContainer.backgroundColor = #colorLiteral(red: 0, green: 0.6150025129, blue: 0.6871898174, alpha: 1)
//        case .none:
//            break
//        }
//    }
//    // MARK: - MESSAGE BUBBLE PADDING
//    
//    private func setMessagePadding(_ messagePadding: TextPaddingStrategy)
//    {
//        messageLabel.textContainerInset = messagePadding.padding
//        messageLabel.invalidateIntrinsicContentSize()
//    }
//    
//    private func editedMessageWidth() -> Double
//    {
//        guard let editedLabel = editedLabel else {return 0}
//        return editedLabel.intrinsicContentSize.width
//    }
//}
//
////MARK: - message padding handler functions
//extension ConversationTableViewCell
//{
//    
////    func adjustMessageLabelPadding()
////    {
////        defer {
//////            self.messageLabel.invalidateIntrinsicContentSize()
//////            self.contentView.invalidateIntrinsicContentSize()
////        }
////
////        if messageLabel.attributedText!.string.contains("took") {
////            print("STOP")
////        }
////
////        guard checkIfMessageComponentsFitIntoLastLine() else
////        {
////            setMessagePadding(.bottom)
////            return
////        }
////
////        if getMessageTextLines().count == 1
////        {
////            let componentsWidth = getMessageComponentsWidth()
////            setMessagePadding(.trailling(space: componentsWidth))
////        }
////    }
////
//    private func getMessagePaddingStrategy() -> TextPaddingStrategy
//    {
//        
//        if messageLabel.attributedText!.string.contains("That was when my") {
//            print("STOP")
//        }
//        
//        let lastLineRemainingWidth = getLastLineRemainingWidth()
//        let componentsWidth = getMessageComponentsWidth()
//        let componentsFitIntoLastLine = lastLineRemainingWidth > componentsWidth
//        
//        let expectedLineWidth = lastLineRemainingWidth + componentsWidth
//        
//        if !componentsFitIntoLastLine
//        {
//            if expectedLineWidth < maxMessageWidth
//            {
//                let spaceLeft = getTextBoundingRect(from: messageLabel)!.width - lastLineRemainingWidth
//                let difference = componentsWidth - spaceLeft
//                return .trailling(space: difference)
//            }
//            return .bottom
//        }
//        return .initial
//        
////        return leftover > 4 /// +4 points reserved space
//    }
//    
//    
//    
//    private func getMessagePaddingStrategy2() -> TextPaddingStrategy
//    {
//        let lastLineRemainingWidth = getLastLineRemainingWidth()
//        let componentsWidth = getMessageComponentsWidth()
//        let totalLineWidth = lastLineRemainingWidth + componentsWidth
//        
//        if totalLineWidth > maxMessageWidth
//        {
//            return .bottom
//        }
//        
//        if totalLineWidth > getTextBoundingRect(from: messageLabel)!.width
//        {
//            let difference = getTextBoundingRect(from: messageLabel)!.width - totalLineWidth
//            return .trailling(space: difference)
//        }
//        return .trailling(space: componentsWidth)
//        
////        if getMessageTextLines().count == 1 || totalLineWidth getTextBoundingRect(from: messageLabel)  {
////            return
////        }
//        
//        
//    }
//    
//    
//    
//    private func getMessageComponentsWidth() -> CGFloat
//    {
//        let allocatedWidthForMessageSide = messageSide == .right ? (seenStatusMark.intrinsicContentSize.width) : 0
//        let componentsWidth = timeStamp.intrinsicContentSize.width + allocatedWidthForMessageSide + editedMessageWidth() + 4 /// +4 extra padding
//        return componentsWidth
//    }
//    
//    private func getLastLineRemainingWidth() -> CGFloat
//    {
//        let lastLineTextWidth = getLastLineMessageTextWidth()
////        let messageWidthPadding = TextPaddingStrategy.initial.padding.left * 2
//        guard let textRectWidth = getTextBoundingRect(from: messageLabel)?.width else {return 0.0}
//        
////        guard getMessageTextLines().count > 1 else {
////            return maxMessageWidth - messageWidthPadding - lastLineTextWidth
//            return textRectWidth - lastLineTextWidth
////        }
//        
////        guard let textBoundingRect = getTextBoundingRect(from: messageLabel) else { return 0.0 }
////        return textBoundingRect.width - lastLineTextWidth
//    }
//    
//    private func getMessageTextLines() -> [YYTextLine] {
//        return messageLabel.textLayout?.lines ?? []
//    }
//    
//    private func getLastLineMessageTextWidth() -> CGFloat
//    {
//        return messageLabel.textLayout?
//            .lines
//            .last?
//            .width ?? 0.0
//    }
//    
//    private func getTextBoundingRect(from view: UIView) -> CGRect?
//    {
//        guard let layout = messageLabel.textLayout else { return nil }
//        return layout.textBoundingRect
//    }
//}
//
//// MARK: - HANDLE IMAGE OF MESSAGE SETUP
//extension ConversationTableViewCell {
//
//    private func configureImageAttachment(data: Data?) {
//        setMessageImage(imageData: data)
//        setMessageImageSize()
//        setMessageLabelAttributedTextImage()
//        setupTimestampBackgroundForImage()
//        setMessagePadding(.image)
//    }
//
//    private func setMessageImage(imageData: Data?) {
//        if let imageData = imageData, let image = convertDataToImage(imageData) {
//            messageImage = image
//        } else {
//            messageImage = UIImage()
//            cellViewModel.fetchImageData()
//        }
//    }
//
//    private func setMessageImageSize() {
//        if let cellImageSize = cellViewModel.cellMessage?.imageSize {
//            let cgSize = CGSize(width: cellImageSize.width, height: cellImageSize.height)
//            let testSize = cellViewModel.getCellAspectRatio(forImageSize: cgSize)
//            messageImage = messageImage?.resize(to: CGSize(width: testSize.width, height: testSize.height)).roundedCornerImage(with: 12)
//        }
//    }
//
//    private func setMessageLabelAttributedTextImage() {
//        let imageAttributedString = NSMutableAttributedString.yy_attachmentString(withContent: messageImage, contentMode: .center, attachmentSize: messageImage!.size, alignTo: UIFont(name: "Helvetica", size: 17)!, alignment: .center)
//
//        messageLabel.attributedText = imageAttributedString
//    }
//
//    private func convertDataToImage(_ data: Data) -> UIImage? {
//        guard let image = UIImage(data: data) else { return nil }
//        return image
//    }
//}
//
//extension ConversationTableViewCell {
//    
//    private func setupMessageBubbleContainer() {
//        contentView.addSubview(messageBubbleContainer)
//        
//        messageBubbleContainer.addSubview(messageLabel)
//        
//        messageBubbleContainer.layer.cornerRadius = 15
//        messageBubbleContainer.translatesAutoresizingMaskIntoConstraints = false
//        
//        messageBubbleContainer.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
//        messageBubbleContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -cellSpacing).isActive = true
//        messageBubbleContainer.widthAnchor.constraint(lessThanOrEqualToConstant: maxMessageWidth).isActive = true
//    }
//    
//    private func setupReplyMessage() {
//        if messageLabelTopConstraints != nil { messageLabelTopConstraints.isActive = false }
//        
//        guard let messageSenderName = cellViewModel.senderNameOfMessageToBeReplied, let messageText = cellViewModel.textOfMessageToBeReplied  else {
//            messageLabelTopConstraints = messageLabel.topAnchor.constraint(equalTo: messageBubbleContainer.topAnchor)
//            messageLabelTopConstraints.isActive = true
//            return
//        }
//        
//        replyMessageLabel.attributedText = createReplyMessageAttributedText(with: messageSenderName, messageText: messageText)
//        replyMessageLabel.numberOfLines = 2
//        replyMessageLabel.layer.cornerRadius = 4
//        replyMessageLabel.clipsToBounds = true
//        replyMessageLabel.backgroundColor = .peterRiver
//        replyMessageLabel.translatesAutoresizingMaskIntoConstraints = false
//        messageBubbleContainer.addSubview(replyMessageLabel)
//        
//        replyMessageLabel.topAnchor.constraint(equalTo: messageBubbleContainer.topAnchor, constant: 10).isActive = true
//        replyMessageLabel.trailingAnchor.constraint(equalTo: messageBubbleContainer.trailingAnchor, constant: -10).isActive = true
//        replyMessageLabel.leadingAnchor.constraint(equalTo: messageBubbleContainer.leadingAnchor, constant: 10).isActive = true
//        messageLabelTopConstraints = messageLabel.topAnchor.constraint(equalTo: replyMessageLabel.bottomAnchor)
//        messageLabelTopConstraints.isActive = true
//    }
//    
//    private func createReplyMessageAttributedText(with senderName: String, messageText: String) -> NSMutableAttributedString
//    {
//        let boldAttributeForName = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 13)]
//        let boldAttributeForText = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 13)]
//        let attributedText = NSMutableAttributedString(string: senderName, attributes: boldAttributeForName)
//        let replyMessageAttributedText = NSAttributedString(string: " \n\(messageText)", attributes: boldAttributeForText)
//        attributedText.append(replyMessageAttributedText)
//        
//        return attributedText
//    }
//    
//    /// Customized reply message to simplify left side indentation color fill and text inset
//    class ReplyMessageLabel: UILabel
//    {
//        private let textInset = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 8)
//        
//        override var intrinsicContentSize: CGSize {
//            get {
//                var contentSize = super.intrinsicContentSize
//                contentSize.height += textInset.top + textInset.bottom
//                contentSize.width += textInset.left + textInset.right
//                return contentSize
//            }
//        }
//        
//        override func drawText(in rect: CGRect) {
//            super.drawText(in: rect.inset(by: textInset))
//        }
//
//        override func draw(_ rect: CGRect) {
//            super.draw(rect)
//            self.fillColor(with: .cyan, width: 5)
//        }
//        
//        private func fillColor(with color: UIColor, width: CGFloat)
//        {
//            let topRect = CGRect(x:0, y:0, width : width, height: self.bounds.height);
//            color.setFill()
//            UIRectFill(topRect)
//        }
//    }
//}
//
////MARK: - skeleton cell
//class SkeletonViewCell: UITableViewCell
//{
//    let customSkeletonView: UIView = {
//        let skeletonView = UIView()
//        skeletonView.translatesAutoresizingMaskIntoConstraints = false
//        skeletonView.isSkeletonable = true
//        skeletonView.skeletonCornerRadius = 15
//        return skeletonView
//    }()
//    
//    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
//        super.init(style: style, reuseIdentifier: reuseIdentifier)
//
//        backgroundColor = #colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 1)
//        setupCustomSkeletonView()
//    }
//    
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//    
//    private func setupCustomSkeletonView()
//    {
//        self.isSkeletonable = true
//        contentView.isSkeletonable = true
//        contentView.addSubview(customSkeletonView)
//        
//        NSLayoutConstraint.activate([
//            customSkeletonView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
//            customSkeletonView.widthAnchor.constraint(equalToConstant: CGFloat((120...270).randomElement()!)),
//            customSkeletonView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
//            customSkeletonView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5)
//        ])
//    }
//}
//
////MARK: - conversation cell enums
//extension ConversationTableViewCell
//{
//    enum MessageSide {
//        case left
//        case right
//    }
//    
//    private enum SeenStatusIcon: String {
//        case single = "icons8-done-64-6"
//        case double = "icons8-double-tick-48-3"
//    }
//    
//    enum TextPaddingStrategy
//    {
//        case initial
//        case bottom
//        case trailling(space: CGFloat)
//        case image
//        
//        var padding: UIEdgeInsets
//        {
//            switch self {
//            case .image: return UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
//            case .bottom: return UIEdgeInsets(top: 6, left: 10, bottom: 20, right: 10)
//            case .initial: return UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 10)
//            case .trailling (let space): return UIEdgeInsets(top: 6, left: 10, bottom: 6, right: space + 10 + 3)
//            }
//        }
//    }
//}
//
//
//
