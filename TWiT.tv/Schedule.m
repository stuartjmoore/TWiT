//
//  Schedule.m
//  TWiT.tv
//
//  Created by Stuart Moore on 1/4/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import "Schedule.h"

@implementation Schedule

- (void)reloadSchedule
{
    self.days = [NSMutableArray array];
    
    NSDate *startMin = [NSDate date];
    NSDate *startMax = [startMin dateByAddingTimeInterval:60*60*24*7];
    
    NSDateFormatter *dateFormatterLocal = [[NSDateFormatter alloc] init];
    [dateFormatterLocal setTimeZone:[NSTimeZone localTimeZone]];
    [dateFormatterLocal setDateFormat:@"yyyy-MM-dd"];
    NSString *startMinString = [dateFormatterLocal stringFromDate:startMin];
    NSString *startMaxString = [dateFormatterLocal stringFromDate:startMax];
    
    NSURL *JSONURLString = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.google.com/calendar/feeds/mg877fp19824mj30g497frm74o@group.calendar.google.com/public/embed?ctz=America%%2FLos_Angeles&start-min=%@T00%%3A00%%3A00-08%%3A00&start-max=%@T00%%3A00%%3A00-08%%3A00&singleevents=true&max-results=720&alt=json", startMinString, startMaxString]];
    
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:JSONURLString];
    [NSURLConnection sendAsynchronousRequest:urlRequest queue:NSOperationQueue.mainQueue
    completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
    {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
        if([httpResponse respondsToSelector:@selector(statusCode)] && httpResponse.statusCode == 200)
        {
            NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            NSArray *showEntries = JSON[@"feed"][@"entry"];
            
            NSCalendar *calendar = NSCalendar.currentCalendar;
            NSDate *fromDate;
            NSDate *toDate;
            
            for(NSDictionary *showEntry in showEntries)
            {
                if([showEntry objectForKey:@"gd$when"] == nil)
                    continue;
                
                NSString *showTitle = [[showEntry objectForKey:@"title"] objectForKey:@"$t"];
                NSString *startTimeString = [[[showEntry objectForKey:@"gd$when"] lastObject] objectForKey:@"startTime"];
                NSString *endTimeString = [[[showEntry objectForKey:@"gd$when"] lastObject] objectForKey:@"endTime"];
                
                showTitle = [showTitle stringByReplacingOccurrencesOfString:@"&#39;" withString:@"’"];
                showTitle = [showTitle stringByReplacingOccurrencesOfString:@"&#38;" withString:@"&"];
                showTitle = [showTitle stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];
                showTitle = [showTitle stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                
                if(startTimeString.length > 20)
                    startTimeString = [startTimeString stringByReplacingOccurrencesOfString:@":"
                                                                                 withString:@""
                                                                                    options:0
                                                                                      range:NSMakeRange(20, startTimeString.length-20)];
                if(endTimeString.length > 20)
                    endTimeString = [endTimeString stringByReplacingOccurrencesOfString:@":"
                                                                             withString:@""
                                                                                options:0
                                                                                  range:NSMakeRange(20, endTimeString.length-20)];
                
                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZ"];
                [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"America/Los_Angeles"]];
                NSDate *startDate = [dateFormatter dateFromString:startTimeString];
                NSDate *endDate = [dateFormatter dateFromString:endTimeString];
                
                NSDateFormatter *dateFormatterLocal = [[NSDateFormatter alloc] init];
                [dateFormatterLocal setTimeZone:[NSTimeZone localTimeZone]];
                [dateFormatterLocal setDateFormat:@"MMM dd, h:mma"];
                NSTimeInterval duration = [endDate timeIntervalSinceDate:startDate];
                
                NSDictionary *showDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                                showTitle, @"title",
                                                startDate, @"startDate",
                                                endDate, @"endDate",
                                                @(duration/60.0f), @"duration",
                                                nil];
                
                [calendar rangeOfUnit:NSDayCalendarUnit
                            startDate:&fromDate
                             interval:NULL
                              forDate:[NSDate date]];
                
                [calendar rangeOfUnit:NSDayCalendarUnit
                            startDate:&toDate
                             interval:NULL
                              forDate:startDate];
                
                int daysAway = [[calendar components:NSDayCalendarUnit
                                            fromDate:fromDate
                                              toDate:toDate
                                             options:0] day];
                
                if(daysAway < 0)
                    continue;
                
                while(daysAway >= _days.count)
                    [_days addObject:[NSMutableArray array]];
                
                NSMutableArray *shows = [_days objectAtIndex:daysAway];
                
                [shows addObject:showDictionary];
            }
            
            for(NSMutableArray *shows in _days)
            {
                [shows sortUsingComparator:(NSComparator)^(id obj1, id obj2)
                 {
                     NSDate *startA = [obj1 objectForKey:@"startDate"];
                     NSDate *startB = [obj2 objectForKey:@"startDate"];
                     return startB == [startA earlierDate:startB];
                 }];
            }
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ScheduleDidUpdate" object:self userInfo:nil];
    }];
}

@end
