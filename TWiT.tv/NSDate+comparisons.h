//
//  NSDate+comparisons.h
//  TWiT.tv
//
//  Created by Stuart Moore on 1/7/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (comparisons)

+ (BOOL)is24Hour;

- (BOOL)isToday;
- (BOOL)isTomorrow;

- (BOOL)isBeforeNow;
- (BOOL)isAfterNow;

- (float)floatTime;

+ (int)dayFromName:(NSString*)name;
+ (NSString*)longNameFromDay:(int)day;
+ (NSString*)shortNameFromDay:(int)day;

@end
