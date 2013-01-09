//
//  Schedule.m
//  TWiT.tv
//
//  Created by Stuart Moore on 1/9/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import "Schedule.h"
#import "NSDate+comparisons.h"

@implementation Schedule

- (NSUInteger)daysAfterNow
{
    if(self.days.count == 0)
        return 0;
    
    NSArray *today = self.days[0];
    int count = self.days.count;
    
    for(NSDictionary *show in today)
    {
        NSDate *startDate = show[@"startDate"];
        NSDate *endDate = show[@"endDate"];
        
        if(startDate.isBeforeNow && endDate.isAfterNow)
        {
            if(today.lastObject == show)
                count--;
            break;
        }
        else if(startDate.isAfterNow && endDate.isAfterNow)
        {
            if(today.lastObject == show)
                count--;
            break;
        }
    }
    return count;
}

- (NSDictionary*)currentShow
{
    NSDictionary *currentShow;
    
    BOOL tryTomorrow = YES;
    int i = 0;
    do
    {
        NSArray *today = self.days[i];
        for(NSDictionary *show in today)
        {
            NSDate *endDate = show[@"endDate"];
            
            if(endDate.isAfterNow)
            {
                currentShow = show;
                tryTomorrow = NO;
                break;
            }
        }
        i++;
    } while(tryTomorrow);

    return currentShow;
}

- (NSString*)stringFromStart:(NSDate*)startDate andEnd:(NSDate*)endDate
{
    NSString *string = @"";
    
    if(startDate.isBeforeNow && endDate.isAfterNow)
    {
        string = @"Live";
    }
    else if(startDate.isAfterNow && endDate.isAfterNow)
    {
        NSInteger interval = startDate.timeIntervalSinceNow;
        if(interval > 24*60*60) // More than 24 hours away
        {
            string = @"Tomorrow";
        }
        else if(interval > 5*60*60) // More than 5 hours away
        {
            NSDateFormatter *dateFormatterLocal = [[NSDateFormatter alloc] init];
            [dateFormatterLocal setTimeZone:[NSTimeZone localTimeZone]];
            [dateFormatterLocal setDateFormat:@"h:mm a"];
            string = [dateFormatterLocal stringFromDate:startDate];
        }
        else if(interval > 10*60) // 5 hours to 10 minutes away
        {
            NSInteger minutes = (interval / 60) % 60;
            NSInteger hours = (interval / 3600);
            string = [NSString stringWithFormat:@"%ih %02im", hours, minutes];
        }
        else // 10 minutes away
            string = @"Pre-show";
    }
    
    return string;
}

@end
