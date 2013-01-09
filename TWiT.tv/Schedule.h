//
//  Schedule.h
//  TWiT.tv
//
//  Created by Stuart Moore on 1/9/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Schedule : NSObject

@property (nonatomic, strong) NSArray *days;

- (NSUInteger)daysAfterNow;

- (NSDictionary*)currentShow;
- (NSString*)stringFromStart:(NSDate*)startDate andEnd:(NSDate*)endDate;

@end
