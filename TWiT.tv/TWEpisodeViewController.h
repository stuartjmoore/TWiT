//
//  TWEpisodeViewController.h
//  TWiT.tv
//
//  Created by Stuart Moore on 12/29/12.
//  Copyright (c) 2012 Stuart Moore. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Episode, TWPlayButton;

@interface TWEpisodeViewController : UIViewController

@property (strong, nonatomic) Episode *episode;

@property (weak, nonatomic) IBOutlet UIImageView *posterView;
@property (weak, nonatomic) IBOutlet TWPlayButton *playButton;
@property (weak, nonatomic) IBOutlet UIView *gradientView;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel, *timeLabel, *numberLabel, *guestsLabel;
@property (weak, nonatomic) IBOutlet UITextView *descLabel;

@end
