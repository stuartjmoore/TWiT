//
//  Duration.swift
//  The TWiT Network
//
//  Created by Stuart Moore on 10/18/15.
//  Copyright © 2015 Stuart J. Moore. All rights reserved.
//

import Foundation

struct ScheduleDuration: CustomStringConvertible {

    let hours: Int
    let minutes: Int
    let seconds: Int

    init(hours: Int, minutes: Int, seconds: Int) {
        self.hours = hours
        self.minutes = minutes
        self.seconds = seconds
    }

    init(fromDate: NSDate, toDate: NSDate) {
        let components = NSCalendar.currentCalendar().components([.Hour, .Minute, .Second], fromDate: fromDate, toDate: toDate, options: [])
        self.init(hours: components.hour, minutes: components.minute, seconds: components.second)
    }

    var timeInterval: NSTimeInterval {
        return NSTimeInterval(hours * 60 * 60 + minutes * 60 + seconds)
    }

    var description: String {
        let formatter = NSNumberFormatter()
        formatter.minimumIntegerDigits = 2

        let minutesString = formatter.stringFromNumber(minutes) ?? "00"
        let secondsString = formatter.stringFromNumber(seconds) ?? "00"

        return "\(hours):\(minutesString):\(secondsString)"
    }
    
}

extension ScheduleDuration: Hashable, Equatable, Comparable {
    var hashValue: Int {
        return timeInterval.hashValue
    }
}

func ==(lhs: ScheduleDuration, rhs: ScheduleDuration) -> Bool {
    return lhs.timeInterval == rhs.timeInterval
}

func <(lhs: ScheduleDuration, rhs: ScheduleDuration) -> Bool {
    return lhs.timeInterval < rhs.timeInterval
}
