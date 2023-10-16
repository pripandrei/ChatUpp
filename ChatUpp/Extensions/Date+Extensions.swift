//
//  Date+Extensions.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/16/23.
//

import Foundation

extension Date {
    func formatToHoursAndMinutes() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat  = "hh:m"
        let time = formatter.string(from: self)
        return time
    }
}
