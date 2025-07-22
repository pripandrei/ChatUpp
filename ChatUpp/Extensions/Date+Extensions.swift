//
//  Date+Extensions.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/16/23.
//

import Foundation

extension Date {
    func toLocalTime() -> Date {
           let timeZone = TimeZone.current
           let seconds = TimeInterval(timeZone.secondsFromGMT(for: self))
           return Date(timeInterval: seconds, since: self)
       }
    
    func formatToHoursAndMinutes() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat  = "HH:mm"
        let time = formatter.string(from: self)
        return time
    }

    func formatToYearMonthDay() -> Date? {
        let dateString = self.formatToYearMonthDayCustomString()
        return DateFormatter.customDateFormatterForYearMonthDay.date(from: dateString)
    }
    
    func formatToYearMonthDayCustomString() -> String {
        return DateFormatter.customDateFormatterForYearMonthDay.string(from: self)
    }
}

extension DateFormatter {
    static var customDateFormatterForYearMonthDay: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        return dateFormatter
    }
    
    static var currentTimeZoneDateFormatter: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = .current
        return dateFormatter
    }
}
