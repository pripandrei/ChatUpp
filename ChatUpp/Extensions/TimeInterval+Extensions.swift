//
//  TimeInter.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 11/14/25.
//

import Foundation

extension TimeInterval
{
    /// returns string representation of time in minutes and seconds (ex. 5:08)
    /// 
    var mmSS: String
    {
        guard self.isFinite else { return "0:00" }

        let safeTime = max(self, 0)

        let minutes = Int(safeTime) / 60
        let seconds = Int(safeTime) % 60

        return String(format: "%d:%02d", minutes, seconds)
    }
}
