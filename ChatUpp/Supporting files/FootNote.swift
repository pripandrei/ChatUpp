//
//  FootNote.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 7/3/25.
//

//MARK: - [1].

/// We disable insertion animation, because we need to both
/// animate insertion of message and scroll to bottom at the same time.
/// If we dont do this, conflict occurs and results in glitches
/// Instead we will animate contentOffset
/// This is not the case if table content is scrolled,
/// meaning, cell is not visible


//MARK: - [2].
/// When additional messages are fetched,
/// and they contain very last/recent message,
/// it will not be added through code above,
/// because it already exists in realm
/// This dirty fix adds last (recent) message to realm
/// so that it becomes managed

//MARK: - [3].
/// wait for initial table scroll to finish,
/// before fetching and inserting messages
/// (some times messages are fetched and inserted in table view
/// faster than scroll is finished, resulting in a glitch)

//MARK: - [4].
/// There are two listeners that are set to recent message
/// one in this view model, and second in ChatRoom view model.
/// This cause timing bug with adding new received recent message.
/// So we do not update recent message here if ChatRoomVC is currently opened.
/// We will do it when chat room vc will be closed

//MARK: - [5].
/// If first index path at row 0 and section 0 is not visible
/// we should insert rows/sections with animation 0.0
/// this makes table view to not shift its contentOffset after insertion

//MARK: - [5].
/// Firebase listeners, in regards to it's remove of documents feature,
/// works inconsitent.
/// If chat is already opened and listener is already attached to messages,
/// it will detect changes/removals, as long as you stay in chat and don't remove listener.
/// However, this is not the case if chat is closed and documents were removed.
/// On opening chat, and attaching listener it will some times give removed docs
/// and some times not.
/// We can't rely on this behavior so we introduce our own removed messages checker,
/// which will compare messages from local db with those from remote db,
/// and remove those that are not present in remote but are in local.
