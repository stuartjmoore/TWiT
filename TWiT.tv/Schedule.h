//
//  Schedule.h
//  TWiT.tv
//
//  Created by Stuart Moore on 1/9/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Show;


@interface Event : NSObject

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) Show *show;
@property (nonatomic, strong) NSDate *start, *end;
@property (nonatomic) NSTimeInterval duration;

@end


@interface Schedule : NSObject

@property (nonatomic, strong) NSArray *days;

- (NSUInteger)daysAfterNow;

- (Event*)currentShow;
- (NSString*)stringFromStart:(NSDate*)startDate andEnd:(NSDate*)endDate;

@end
