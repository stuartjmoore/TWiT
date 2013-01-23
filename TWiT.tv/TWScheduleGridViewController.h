//
//  TWScheduleGridViewController.h
//  TWiT.tv
//
//  Created by Stuart Moore on 1/12/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Schedule;

@interface TWScheduleGridViewController : UIViewController <UIScrollViewDelegate>

@property (nonatomic, strong) Schedule *schedule;
@property (nonatomic, weak) IBOutlet UIScrollView *scrollView;
@property (nonatomic, weak) IBOutlet UIView *daysView, *gradientView;
@property (nonatomic, weak) IBOutlet UILabel *day3label, *day4Label, *day5Label, *day6Label, *day7Label;

@property (nonatomic, strong) UIView *nowLine;


- (IBAction)scrollToNow:(UIButton*)sender;

- (IBAction)close:(UIBarButtonItem*)sender;

@end
