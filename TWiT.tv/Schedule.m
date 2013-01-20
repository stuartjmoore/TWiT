//
//  Schedule.m
//  TWiT.tv
//
//  Created by Stuart Moore on 1/9/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import "Schedule.h"
#import "NSDate+comparisons.h"


@implementation Event

- (NSString*)time
{
    NSDateFormatter *dateFormatterLocal = [[NSDateFormatter alloc] init];
    [dateFormatterLocal setTimeZone:[NSTimeZone localTimeZone]];
    [dateFormatterLocal setDateFormat:@"h:mma"];
    return [[dateFormatterLocal stringFromDate:self.start] lowercaseString];
}

- (NSString*)until
{
    NSString *string = @"";
    
    if(self.start.isBeforeNow && self.end.isAfterNow)
    {
        string = @"Live";
    }
    else if(self.start.isAfterNow && self.end.isAfterNow)
    {
        NSInteger interval = self.start.timeIntervalSinceNow;
        
        if(self.start.isTomorrow) // 24 hours away
        {
            string = @"Tomorrow";
        }
        else if(interval > 5*60*60) // More than 5 hours away
        {
            string = self.time;
        }
        else if(interval > 10*60) // 5 hours to 10 minutes away
        {
            NSInteger minutes = (interval / 60) % 60;
            NSInteger hours = (interval / 3600);
            string = [NSString stringWithFormat:@"%ih %02im", hours, minutes];
        }
        else // 10 minutes away
        {
            string = @"Pre-show";
        }
    }
    
    return string;
}

@end


@implementation Schedule

- (Event*)currentShow
{
    if(self.days.count == 0)
        return nil;
    
    Event *currentShow;
    
    BOOL tryTomorrow = YES;
    int i = 0;
    do
    {
        NSArray *today = self.days[i];
        for(Event *show in today)
        {
            if(show.end.isAfterNow)
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

- (Event*)showAfterShow:(Event*)event
{
    Event *nextEvent;
    
    for(NSArray *day in self.days)
    {
        int index = [day indexOfObject:event];
        
        if(index == NSNotFound)
            continue;
        
        index++;
        
        if(index < day.count)
        {
            nextEvent = day[index];
            break;
        }
        else
        {
            int dayIndex = [self.days indexOfObject:day];
            
            dayIndex++;
            
            if(dayIndex < self.days.count)
            {
                NSArray *nextDay = self.days[dayIndex];
                
                if(nextDay.count > 0)
                {
                    nextEvent = nextDay[0];
                    break;
                }
            }
        }
    }
    
    return nextEvent;
}

@end
