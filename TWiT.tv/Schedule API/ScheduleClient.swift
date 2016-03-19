//
//  ScheduleClient.swift
//  The TWiT Network
//
//  Created by Stuart Moore on 10/15/15.
//  Copyright © 2015 Stuart J. Moore. All rights reserved.
//
//  https://calendar.google.com/calendar/embed?src=mg877fp19824mj30g497frm74o@group.calendar.google.com&ctz=America/New_York
//

import Foundation

private let calendarId = "mg877fp19824mj30g497frm74o%40group.calendar.google.com"

class ScheduleClient {

    private static let session: NSURLSession = {
        let configuration = NSURLSessionConfiguration.ephemeralSessionConfiguration()
        configuration.HTTPMaximumConnectionsPerHost = 1
        return NSURLSession(configuration: configuration)
    }()

    private let dateFormatter: NSDateFormatter = {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ" // RFC3339
        formatter.timeZone = NSTimeZone(name: "America/New_York")
        return formatter
    }()

    func week(completion: (([[ScheduleEvent]]) -> Void)) {
        let startDate = NSDate().startOfPreviousDay
        let endDate = startDate.endOfWeek

        eventsStartingFromDate(startDate, toDate: endDate, completion: completion)
    }

    func nextEpisode(completion: (([ScheduleEvent]) -> Void)) {
        eventsStartingFromDate(NSDate(), count: 2) { (scheduled) in
            completion(scheduled.flatMap({ $0 }))
        }
    }

    private func eventsStartingFromDate(startDate: NSDate, toDate endDate: NSDate? = nil, count: Int? = nil, completion: (([[ScheduleEvent]]) -> Void)) {
        guard let keysFilepath = NSBundle.mainBundle().pathForResource("Keys", ofType:"plist"),
              let allKeys = NSDictionary(contentsOfFile: keysFilepath) as? [String:AnyObject],
              let keys = allKeys["Google"] as? [String:String],
              let apiKey = keys["api-key"], referer = keys["referer"] else {
            return print("Unable to get Google key or referer.")
        }

        guard let components = NSURLComponents(string: "https://www.googleapis.com/calendar/v3/calendars/\(calendarId)/events") else {
            return print("Unable to create URL components.")
        }

        let timeMin = dateFormatter.stringFromDate(startDate)

        components.queryItems = [
            NSURLQueryItem(name: "alwaysIncludeEmail", value: "false"),
            NSURLQueryItem(name: "showHiddenInvitations", value: "false"),
            NSURLQueryItem(name: "showDeleted", value: "false"),
            NSURLQueryItem(name: "singleEvents", value: "true"),
            NSURLQueryItem(name: "orderBy", value: "startTime"),
            NSURLQueryItem(name: "timeMin", value: timeMin),
            NSURLQueryItem(name: "timeZone", value: "America/New_York"),
            NSURLQueryItem(name: "fields", value: "items(description,end,hangoutLink,id,start,summary)"),
            NSURLQueryItem(name: "key", value: apiKey)
        ]

        if let endDate = endDate {
            let timeMax = dateFormatter.stringFromDate(endDate)
            components.queryItems?.append(NSURLQueryItem(name: "timeMax", value: timeMax))
        }

        if let count = count {
            components.queryItems?.append(NSURLQueryItem(name: "maxResults", value: String(count)))
        }

        guard let url = components.URL else {
            return print("Unable to create URL.")
        }

        let session = ScheduleClient.session
        let request = NSMutableURLRequest(URL: url)

        request.setValue(referer, forHTTPHeaderField: "Referer")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            guard error == nil else {
                return print(error)
            }

            guard let data = data else {
                return print("No schedule data.")
            }

            guard let JSON = try? NSJSONSerialization.JSONObjectWithData(data, options: []) else {
                return print("Schedule JSON parse failed.")
            }

            guard let items = JSON["items"] as? [[String:AnyObject]] else {
                return print("No schedule items.")
            }

            var scheduled: [[ScheduleEvent]] = []

            for item in items {
                guard let itemId = item["id"] as? String else {
                    return print("No item schedule id.")
                }

                guard let itemTitle = item["summary"] as? String else {
                    return print("No item schedule title.")
                }

                guard let itemStartDateString = item["start"]?["dateTime"] as? String,
                    let itemStartDate = self.dateFormatter.dateFromString(itemStartDateString) else {
                        return print("No item schedule start date.")
                }

                guard let itemEndDateString = item["end"]?["dateTime"] as? String,
                    let itemEndDate = self.dateFormatter.dateFromString(itemEndDateString) else {
                        return print("No item schedule end date.")
                }

                let duration = ScheduleDuration(fromDate: itemStartDate, toDate: itemEndDate)
                let event = ScheduleEvent(showId: "", id: itemId, title: itemTitle, airingDate: itemStartDate, duration: duration)
                let sectionIndex = event.airingDate.daysSeparatingDate(startDate)

                if sectionIndex >= scheduled.count {
                    scheduled.append([event])
                } else {
                    scheduled[sectionIndex].append(event)
                }
            }
            
            dispatch_async(dispatch_get_main_queue()) {
                completion(scheduled)
            }
        }
        
        task.resume()
    }

}
