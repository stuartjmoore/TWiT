//
//  ScheduleConverter.swift
//  TWiT.tv
//
//  Created by Stuart Moore on 3/18/16.
//  Copyright © 2016 Stuart Moore. All rights reserved.
//

import Foundation

class ScheduleConverter: NSObject {

    class func weekWithShows(shows: Set<Show>, completion: (Schedule) -> Void) {
        ScheduleClient().week { (week) in
            let schedule = Schedule()

            schedule.days = week.map { (day) -> [Event] in
                day.map { (scheduleEvent) -> Event in
                    let filteredShows = shows.filter { (show) -> Bool in
                        return scheduleEvent.title.lowercaseString.hasPrefix(show.title.lowercaseString)
                            || scheduleEvent.title.lowercaseString.hasPrefix(show.titleInSchedule.lowercaseString)
                    }

                    let show = filteredShows.first
                    let showTitle = show?.title ?? scheduleEvent.title
                    var showSubtitle = ""

                    if let show = show {
                        showSubtitle = scheduleEvent.title.stringByReplacingOccurrencesOfString(
                            show.titleInSchedule,
                            withString: "",
                            options: .CaseInsensitiveSearch
                        ).stringByReplacingOccurrencesOfString(
                            show.title,
                            withString: "",
                            options: .CaseInsensitiveSearch
                        ).stringByTrimmingCharactersInSet(
                            .whitespaceAndNewlineCharacterSet()
                        ).stringByTrimmingCharactersInSet(
                            .punctuationCharacterSet()
                        )

                        if showSubtitle == showTitle {
                            showSubtitle = ""
                        }
                    }

                    let showEvent = Event()
                    showEvent.title = showTitle
                    showEvent.subtitle = showSubtitle
                    showEvent.show = show
                    showEvent.start = scheduleEvent.airingDate
                    showEvent.end = NSDate(timeInterval: scheduleEvent.duration.timeInterval, sinceDate: showEvent.start)
                    showEvent.duration = scheduleEvent.duration.timeInterval / 60

                    return showEvent
                }
            }

            completion(schedule)
        }
    }

}
