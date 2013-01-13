//
//  TWEpisodeCell.h
//  TWiT.tv
//
//  Created by Stuart Moore on 1/1/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Episode;

@interface TWEpisodeCell : UITableViewCell

@property (nonatomic, strong) Episode *episode;

@property (nonatomic, weak) IBOutlet UIView *topLine, *bottomLine;

@property (nonatomic, weak) IBOutlet UIImageView *albumArt;
@property (nonatomic, weak) IBOutlet UILabel *numberLabel;

@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *subtitleLabel;

@property (nonatomic) float progress;
@property (nonatomic, weak) IBOutlet UIImageView *downloadBackground;

@end
