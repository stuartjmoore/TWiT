//
//  NSDate+comparisons.m
//  TWiT.tv
//
//  Created by Stuart Moore on 1/7/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import "NSDate+comparisons.h"

@implementation NSDate (comparisons)

+ (BOOL)is24Hour
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setLocale:[NSLocale currentLocale]];
    [formatter setDateStyle:NSDateFormatterNoStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    
    NSString *dateString = [formatter stringFromDate:[NSDate date]];
    NSRange amRange = [dateString rangeOfString:formatter.AMSymbol];
    NSRange pmRange = [dateString rangeOfString:formatter.PMSymbol];
    
    return (amRange.location == NSNotFound && pmRange.location == NSNotFound);
}

- (BOOL)isToday
{
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSInteger components = (NSEraCalendarUnit|NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit);
    
    NSDateComponents *startTimeComponents = [cal components:components fromDate:self];
    NSDate *simpleSelf = [NSCalendar.currentCalendar dateFromComponents:startTimeComponents];
    
    NSDateComponents *todayComponents = [cal components:components fromDate:[NSDate date]];
    NSDate *simpleToday = [NSCalendar.currentCalendar dateFromComponents:todayComponents];
    
    return [simpleSelf isEqualToDate:simpleToday];
}
- (BOOL)isTomorrow
{
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSInteger components = (NSEraCalendarUnit|NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit);
    
    NSDateComponents *startTimeComponents = [cal components:components fromDate:self];
    NSDate *simpleSelf = [NSCalendar.currentCalendar dateFromComponents:startTimeComponents];
    
    NSDate *tomorrow = [NSDate dateWithTimeIntervalSinceNow:86400];
    NSDateComponents *todayComponents = [cal components:components fromDate:tomorrow];
    NSDate *simpleToday = [NSCalendar.currentCalendar dateFromComponents:todayComponents];
    
    return [simpleSelf isEqualToDate:simpleToday];
}

- (BOOL)isBeforeNow
{
    return [self timeIntervalSinceNow] /*- 86400*/ < 0;
}
- (BOOL)isAfterNow
{
    return [self timeIntervalSinceNow] /*- 86400*/ > 0;
}

- (float)floatTime
{
    NSDateFormatter *hourFormatter = [[NSDateFormatter alloc] init];
    [hourFormatter setDateFormat:@"H"];
    float hour = [[hourFormatter stringFromDate:self] floatValue];
    
    NSDateFormatter *minuteFormatter = [[NSDateFormatter alloc] init];
    [minuteFormatter setDateFormat:@"m"];
    float minute = [[minuteFormatter stringFromDate:self] floatValue] / 60.0f;
    
    return hour + minute;
}

+ (int)dayFromName:(NSString*)name
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

+ (NSString*)longNameFromDay:(int)day
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
+ (NSString*)shortNameFromDay:(int)day
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
