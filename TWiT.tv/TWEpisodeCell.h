//
//  TWEpisodeCell.h
//  TWiT.tv
//
//  Created by Stuart Moore on 1/1/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Episode;

@protocol TWiTEpisodeCellDelegate <NSObject>
- (void)tableView:(UITableView*)tableView didSelectAccessoryAtIndexPath:(NSIndexPath*)indexPath;
@end

@interface TWEpisodeCell : UITableViewCell

@property (nonatomic, strong) Episode *episode;

@property (nonatomic, weak) id<UITableViewDelegate> delegate;
@property (nonatomic, strong) NSIndexPath *indexPath;
@property (nonatomic, weak) UITableView *table;

@property (nonatomic, weak) IBOutlet UIView *contentView;

@property (nonatomic, weak) IBOutlet UIView *topLine, *bottomLine;

@property (nonatomic, weak) IBOutlet UIImageView *albumArt;
@property (nonatomic, weak) IBOutlet UILabel *numberLabel;
@property (nonatomic, weak) IBOutlet UILabel *dateWordLabel, *dateNumLabel;

@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *subtitleLabel;

@property (nonatomic, weak) IBOutlet UIImageView *downloadedIcon;
@property (nonatomic, weak) IBOutlet UIButton *quickPlayButton;

@property (nonatomic) CGFloat progress;
@property (nonatomic, weak) IBOutlet UIImageView *downloadBackground;

@property (nonatomic, weak) IBOutlet UIView *swipeBackgroundView, *swipeConfirmationView;
@property (nonatomic, weak) IBOutlet UILabel *swipeLabel;

- (IBAction)quickPlayPressed:(UIButton*)sender;

@end
