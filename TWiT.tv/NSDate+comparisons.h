//
//  NSDate+comparisons.h
//  TWiT.tv
//
//  Created by Stuart Moore on 1/7/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (comparisons)

- (BOOL)isToday;
- (BOOL)isTomorrow;

- (BOOL)isBeforeNow;
- (BOOL)isNow;
- (BOOL)isAfterNow;

- (CGFloat)floatTime;

+ (NSInteger)dayFromName:(NSString*)name;
+ (NSString*)longNameFromDay:(NSInteger)day;
+ (NSString*)shortNameFromDay:(NSInteger)day;

@end
