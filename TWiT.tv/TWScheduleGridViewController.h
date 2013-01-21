//
//  TWScheduleGridViewController.h
//  TWiT.tv
//
//  Created by Stuart Moore on 1/12/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Schedule;

@interface TWScheduleGridViewController : UIViewController

@property (nonatomic, strong) Schedule *schedule;

- (IBAction)close:(UIBarButtonItem*)sender;

@end
