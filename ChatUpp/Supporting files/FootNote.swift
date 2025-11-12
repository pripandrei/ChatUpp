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
/// We will do it if chat room vc is closed

//MARK: - [5].
/// If first index path at row 0 and section 0 is not visible
/// we should insert rows/sections with animation 0.0
/// this makes table view to not shift its contentOffset after insertion

//MARK: - [6].
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

//MARK: - [7].
/// If unseen messages count from realm are equal to that from firebase,
/// it means that we have all unseen messages up to recent one,
/// so we can safely attach listener to upcoming messages.
/// If realms unseen count is bigger, it still safe to attach listener
/// because it means that some messages were removed from remote db,
/// before synchronization with local was made,
/// but we still can grab last message and listen up from it by id
/// (or timestamp if last message was removed. See how addListenerToUpcomingMessages works)

//MARK: - [8].
/// When we don't posses the range of messages from the last paginated one
/// till the chat recent message, then there is a gap of messages in our local db that needs to be fetched from remote db.
/// So we need to dropLast (chat recent message) to not display it in caht and
/// fetch/paginate from remote db until we hit recent message to display

//MARK: - [9].
/// each title message comes from a user that created this title
/// (i.e when entered group), so instead of checking each message of group,
/// we can check messages if they are title type, and from them grab sender ID
/// and see if we have this sender (user) locally, to display their avatar along the message

//MARK: - [10].
/// IMPORTANT: Keep this case order for iteration on image creation
/// For more info see how 'createImageSamples' function
/// from ImageSampleRepository works
/// 
//MARK: - [11].
/// When user B (the one that is not self) removes chat, it will become invalid,
/// however listener of messages will still receive removed messages.
/// In this case, we dont need to perform any updates with received messages.

//MARK: - [12].
/// If message seen status was updated locally during network off,
/// we should not just add the firestore message to realm
/// because it will override it and message will be set to seen status false,
/// again. So we update firestore message seen status before adding to realm

//MARK: - [13]
/// When pagination of messages happens, it offsets content of table view
/// to the very first cell. After that it wil be adjustead back,
/// but during this phase we dont want to catche the smalles index path,
/// so we just ignore updates ignore updates

//MARK: - [14]
/// Because render of animations can still be in process,
/// we need to queue destruction of animations on actor (StickerAnimationManager) where render takes place.
/// This way animations will be destroyed only after final render will come to it's end.
///

//MARK: - [15]
///
/// KeyboardService is used only to get the height of the keyboard from current device that the app is running on

//MARK: - [16]
//
/// This code is a workaround to avoid content offset shift on new rows/sections insertion
/// EXPLANETION:
/// On new cells/sections insertion, if tableView contentOffset y is at the inital position y (-97.6...),
/// tableView will animate scrolling to the last inserted cell, we want this to avoid,
/// So we offset a bit content, which will result in content remaining at the same position after insertion

