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

@end
