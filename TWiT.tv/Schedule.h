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

@property (nonatomic, strong) NSString *title, *subtitle;
@property (nonatomic, strong) Show *show;
@property (nonatomic, strong) NSDate *start, *end;
@property (nonatomic) NSTimeInterval duration;

- (NSString*)until;
- (NSString*)time;

@end


@interface Schedule : NSObject

@property (nonatomic, strong) NSArray *days;

- (Event*)currentShow;

@end
