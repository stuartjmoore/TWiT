//
//  TWEpisodeCell.m
//  TWiT.tv
//
//  Created by Stuart Moore on 1/1/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import "TWEpisodeCell.h"
#import "Episode.h"
#import "Show.h"

@implementation TWEpisodeCell

- (void)awakeFromNib
{
    UIImage *swipeButtonBackground = [self.swipeCancelButton backgroundImageForState:UIControlStateNormal];
    swipeButtonBackground = [swipeButtonBackground resizableImageWithCapInsets:UIEdgeInsetsMake(6, 6, 7, 6)];
    [self.swipeCancelButton setBackgroundImage:swipeButtonBackground forState:UIControlStateNormal];
    [self.swipeDeleteButton setBackgroundImage:swipeButtonBackground forState:UIControlStateNormal];
}

- (void)setEpisode:(Episode*)episode
{
    _episode = episode;

    BOOL isPublished = (episode.published != nil);
    self.titleLabel.enabled = isPublished;
    self.subtitleLabel.enabled = isPublished;
    self.numberLabel.enabled = isPublished;
    self.quickPlayButton.enabled = isPublished;
    self.albumArt.alpha = isPublished ? 1 : 0.5f;
    
    self.numberLabel.text = @(episode.number).stringValue;
    self.albumArt.image = episode.show.albumArt.image;
    self.titleLabel.text = episode.title;
    self.subtitleLabel.text = episode.show.title;
    
    self.accessibilityHint = isPublished ? @"Opens the episode view." : @"Syncs the episode.";

    if(self.selected)
        self.numberLabel.textColor = [UIColor whiteColor];
    else if(!episode.watched)
        self.numberLabel.textColor = [UIColor colorWithRed:239/255.0 green:79/255.0 blue:61/255.0 alpha:1];
    else
        self.numberLabel.textColor = [UIColor blackColor];
    
    if(self.selected)
        self.downloadedIcon.hidden = YES;
    else
        self.downloadedIcon.hidden = (!self.episode.downloadedEnclosures);
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    if(selected)
    {
        self.contentView.backgroundColor = self.tintColor;
        self.titleLabel.textColor = [UIColor whiteColor];
        self.subtitleLabel.textColor = [UIColor whiteColor];
        self.numberLabel.textColor = [UIColor whiteColor];
        
        self.topLine.hidden = YES;
        self.bottomLine.hidden = YES;
        self.quickPlayButton.hidden = YES;
        self.downloadedIcon.hidden = YES;
    }
    else
    {
        self.contentView.backgroundColor = [UIColor whiteColor];
        self.titleLabel.textColor = [UIColor blackColor];
        self.subtitleLabel.textColor = [UIColor darkGrayColor];
        
        if(!self.episode.watched)
            self.numberLabel.textColor = [UIColor colorWithRed:239/255.0 green:79/255.0 blue:61/255.0 alpha:1];
        else
            self.numberLabel.textColor = [UIColor blackColor];
        
        self.topLine.hidden = NO;
        self.bottomLine.hidden = NO;
        self.quickPlayButton.hidden = NO;
        self.downloadedIcon.hidden = (!self.episode.downloadedEnclosures);
    }
}

- (void)setProgress:(float)progress
{
    _progress = progress;
    
    CGRect frame = self.contentView.frame;
    float width = frame.size.width * progress;
    
    frame.origin.x = width;
    frame.size.width -= width;
    
    self.downloadBackground.frame = frame;
    self.downloadBackground.hidden = (progress == 1) ? YES : NO;
}

#pragma mark - Actions

- (IBAction)quickPlayPressed:(UIButton*)sender
{
    [self.delegate tableView:self.table accessoryButtonTappedForRowWithIndexPath:self.indexPath];
}

@end
