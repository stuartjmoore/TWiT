//
//  TWScheduleCell.m
//  TWiT.tv
//
//  Created by Stuart Moore on 1/10/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import "TWScheduleCell.h"
#import "NSDate+comparisons.h"
#import "Schedule.h"

@implementation TWScheduleCell

- (void)setEvent:(Event*)event
{
    _event = event;
    
    if(event.end.isBeforeNow)
    {
        self.timeLabel.textColor = [UIColor grayColor];
        self.titleLabel.textColor = [UIColor grayColor];
        self.subtitleLabel.textColor = [UIColor grayColor];
    }
    else
    {
        self.timeLabel.textColor = [UIColor blackColor];
        self.titleLabel.textColor = [UIColor blackColor];
        self.subtitleLabel.textColor = [UIColor darkGrayColor];
    }
    
    self.timeLabel.text = event.time;
    self.titleLabel.text = event.title;
    self.subtitleLabel.text = event.subtitle;
}

@end
