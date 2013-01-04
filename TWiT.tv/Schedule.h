//
//  Schedule.h
//  TWiT.tv
//
//  Created by Stuart Moore on 1/4/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Schedule : NSObject

@property (strong, nonatomic) NSMutableArray *days;

- (void)reloadSchedule;

@end
