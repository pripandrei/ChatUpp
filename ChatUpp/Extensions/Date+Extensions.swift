//
//  Date+Extensions.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/16/23.
//

import Foundation

extension Date
{
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
    
    func formattedAsRelativeDayLabel() -> String
    {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        
        if calendar.isDateInToday(self) {
            return "Today"
        } else if calendar.isDateInYesterday(self) {
            return "Yesterday"
        } else if calendar.isDate(self, equalTo: Date(), toGranularity: .year) {
            formatter.dateFormat = "MMMM d"
        } else {
            formatter.dateFormat = "MMMM d, yyyy"
        }
        
        return formatter.string(from: self)
    }
    
    func formattedAsTimeAgo() -> String
    {
        let now = Date()
        let secondsAgo = now.timeIntervalSince(self)
        
        if secondsAgo < 60 {
            return "just now"
        } else if secondsAgo < 3600 {
            let minutes = Int(secondsAgo / 60)
            return "\(minutes) minutes ago"
        } else if secondsAgo < 86400 {
            let hours = Int(secondsAgo / 3600)
            return "\(hours) hours ago"
        } else {
            let calendar = Calendar.current
            let dateFormatter = DateFormatter()
            
            if calendar.component(.year, from: self) < calendar.component(.year, from: now)
            {
                // Show date with year if it's from a different year
                dateFormatter.dateFormat = "MMM d, yyyy" // Example: "Aug 3, 2023"
            } else {
                // Same year: omit year
                dateFormatter.dateFormat = "MMM d" // Example: "Aug 3"
            }
            
            return dateFormatter.string(from: self)
        }
    }
    
    func formattedAsCompactDate() -> String
    {
        let now = Date()
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        
        // time is today
        if calendar.isDateInToday(self)
        {
            dateFormatter.dateFormat = "HH:mm"
            return dateFormatter.string(from: self)
        }
        
        // time is within current weak
        if calendar.component(.weekOfYear, from: self) ==
            calendar.component(.weekOfYear, from: now)
            &&
            calendar.component(.yearForWeekOfYear, from: self) ==
            calendar.component(.yearForWeekOfYear, from: now)
        {
            dateFormatter.dateFormat = "E"
            return dateFormatter.string(from: self)
        }
        
        // time is within current year
        if calendar.isDate(self, equalTo: now, toGranularity: .year)
        {
            dateFormatter.dateFormat = "dd.MM"
            return dateFormatter.string(from: self)
        }
        
        // time outside the current year
        dateFormatter.dateFormat = "dd.MM.yyyy"
        return dateFormatter.string(from: self)
    }
}

extension DateFormatter
{
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
