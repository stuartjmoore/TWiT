//
//  TWScheduleCell.h
//  TWiT.tv
//
//  Created by Stuart Moore on 1/10/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Event;

@interface TWScheduleCell : UITableViewCell

@property (nonatomic, strong) Event *event;
@property (nonatomic, weak) IBOutlet UILabel *timeLabel, *titleLabel, *subtitleLabel;

@end
