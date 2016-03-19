//
//  Event.swift
//  The TWiT Network
//
//  Created by Stuart Moore on 10/18/15.
//  Copyright © 2015 Stuart J. Moore. All rights reserved.
//

import Foundation

struct ScheduleEvent {

    let showId: String

    let id: String
    let title: String

    let airingDate: NSDate
    let duration: ScheduleDuration

}

extension ScheduleEvent: Hashable, Equatable, Comparable {
    var hashValue: Int {
        return id.hashValue
    }
}

func ==(lhs: ScheduleEvent, rhs: ScheduleEvent) -> Bool {
    return lhs.id == rhs.id
}

func <(lhs: ScheduleEvent, rhs: ScheduleEvent) -> Bool {
    return lhs.airingDate.earlierDate(rhs.airingDate) === lhs.airingDate
}
