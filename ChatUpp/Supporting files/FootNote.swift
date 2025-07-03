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
