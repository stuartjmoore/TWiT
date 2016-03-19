//
//  NSDate+Calendar.swift
//  The TWiT Network
//
//  Created by Stuart Moore on 11/8/15.
//  Copyright © 2015 Stuart J. Moore. All rights reserved.
//

import Foundation

extension NSDate {

    var timeString: String {
        let formatter = NSDateFormatter()
        formatter.timeStyle = .ShortStyle
        return formatter.stringFromDate(self)
    }

    var startOfDay: NSDate {
        let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian) ?? NSCalendar.autoupdatingCurrentCalendar()
        return calendar.startOfDayForDate(self) ?? self
    }

    var startOfPreviousDay: NSDate {
        let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian) ?? NSCalendar.autoupdatingCurrentCalendar()
        let components = NSDateComponents(day: -1)

        let startOfDay = calendar.startOfDayForDate(self)
        let previousDay = calendar.dateByAddingComponents(components, toDate: startOfDay, options: [])

        return previousDay ?? self
    }

    var endOfWeek: NSDate {
        let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian) ?? NSCalendar.autoupdatingCurrentCalendar()
        let components = NSDateComponents(weekOfYear: 1, second: -1)

        let startOfDay = calendar.startOfDayForDate(self)
        let endOfWeek = calendar.dateByAddingComponents(components, toDate: startOfDay, options: [])

        return endOfWeek ?? self
    }

    var daysSeparatingToday: Int {
        let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian) ?? NSCalendar.autoupdatingCurrentCalendar()
        let components = calendar.components(.Day, fromDate: NSDate().startOfDay, toDate: startOfDay, options: [])
        return components.day
    }

    func daysSeparatingDate(date: NSDate) -> Int {
        let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian) ?? NSCalendar.autoupdatingCurrentCalendar()
        let components = calendar.components(.Day, fromDate: date, toDate: self, options: [])
        return components.day
    }

}

extension NSDateFormatter {

    convenience init(dateFormat: String) {
        self.init()
        self.dateFormat = dateFormat
    }
    
}

extension NSDateComponents {

    convenience init(day: Int) {
        self.init()
        self.day = day
    }

    convenience init(weekOfYear: Int, second: Int) {
        self.init()
        self.weekOfYear = weekOfYear
        self.second = second
    }
    
}
