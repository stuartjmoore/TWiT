//
//  NSDate+comparisons.m
//  TWiT.tv
//
//  Created by Stuart Moore on 1/7/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import "NSDate+comparisons.h"

@implementation NSDate (comparisons)

- (BOOL)isToday
{
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSInteger components = (NSEraCalendarUnit|NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit);
    
    NSDateComponents *startTimeComponents = [cal components:components fromDate:self];
    NSDate *simpleSelf = [cal dateFromComponents:startTimeComponents];
    
    NSDateComponents *todayComponents = [cal components:components fromDate:[NSDate date]];
    NSDate *simpleToday = [cal dateFromComponents:todayComponents];
    
    return [simpleSelf isEqualToDate:simpleToday];
}
- (BOOL)isTomorrow
{
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSInteger components = (NSEraCalendarUnit|NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit);
    
    NSDateComponents *startTimeComponents = [cal components:components fromDate:self];
    NSDate *simpleSelf = [cal dateFromComponents:startTimeComponents];
    
    NSDate *tomorrow = [NSDate dateWithTimeIntervalSinceNow:86400];
    NSDateComponents *tomorrowComponents = [cal components:components fromDate:tomorrow];
    NSDate *simpleTomorrow = [cal dateFromComponents:tomorrowComponents];
    
    return [simpleSelf isEqualToDate:simpleTomorrow];
}

- (BOOL)isBeforeNow
{
    return [self timeIntervalSinceNow] < 0;
}
- (BOOL)isNow
{
    return [self timeIntervalSinceNow] == 0;
}
- (BOOL)isAfterNow
{
    return [self timeIntervalSinceNow] > 0;
}

- (CGFloat)floatTime
{
    NSDateFormatter *hourFormatter = [[NSDateFormatter alloc] init];
    [hourFormatter setDateFormat:@"H"];
    CGFloat hour = [[hourFormatter stringFromDate:self] floatValue];
    
    NSDateFormatter *minuteFormatter = [[NSDateFormatter alloc] init];
    [minuteFormatter setDateFormat:@"m"];
    CGFloat minute = [[minuteFormatter stringFromDate:self] floatValue] / 60.0f;
    
    return hour + minute;
}

+ (NSInteger)dayFromName:(NSString*)name
{
    if([name isEqualToString:@"SU"])
        return 1;
    else if([name isEqualToString:@"MO"])
        return 2;
    else if([name isEqualToString:@"TU"])
        return 3;
    else if([name isEqualToString:@"WE"])
        return 4;
    else if([name isEqualToString:@"TH"])
        return 5;
    else if([name isEqualToString:@"FR"])
        return 6;
    else if([name isEqualToString:@"SA"])
        return 7;
    
    return -1;
}

+ (NSString*)longNameFromDay:(NSInteger)day
{
    if(day == 1)
        return @"Sundays";
    else if(day == 2)
        return @"Mondays";
    else if(day == 3)
        return @"Tuesdays";
    else if(day == 4)
        return @"Wednesdays";
    else if(day == 5)
        return @"Thursdays";
    else if(day == 6)
        return @"Fridays";
    else if(day == 7)
        return @"Saturdays";
    
    return @"";
}
+ (NSString*)shortNameFromDay:(NSInteger)day
{
    if(day == 1)
        return @"Sun";
    else if(day == 2)
        return @"Mon";
    else if(day == 3)
        return @"Tues";
    else if(day == 4)
        return @"Wed";
    else if(day == 5)
        return @"Thur";
    else if(day == 6)
        return @"Fri";
    else if(day == 7)
        return @"Sat";
    
    return @"";
}

@end
