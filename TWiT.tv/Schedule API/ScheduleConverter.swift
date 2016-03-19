//
//  ScheduleConverter.swift
//  TWiT.tv
//
//  Created by Stuart Moore on 3/18/16.
//  Copyright © 2016 Stuart Moore. All rights reserved.
//

import Foundation

class ScheduleConverter: NSObject {

    class func week(completion: (Schedule) -> Void) {
        ScheduleClient().week { (week) in
            let schedule = Schedule()

            for day in week {
                for event in day {
                    print("Event: \(event)")
                }
            }

            completion(schedule)
        }
    }

}
