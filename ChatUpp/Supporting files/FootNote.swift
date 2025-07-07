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
