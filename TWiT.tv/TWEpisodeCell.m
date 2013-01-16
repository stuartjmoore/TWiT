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

- (void)setEpisode:(Episode*)episode
{
    _episode = episode;
    
    self.numberLabel.text = @(episode.number).stringValue;
    self.albumArt.image = episode.show.albumArt.image;
    self.titleLabel.text = episode.title;
    self.subtitleLabel.text = episode.show.title;
    
    CGSize size = [self.titleLabel.text sizeWithFont:self.titleLabel.font];
    
    if(size.width > self.titleLabel.frame.size.width)
    {
        self.titleLabel.numberOfLines = 2;
        
        CGRect titleFrame = self.titleLabel.frame;
        titleFrame.origin.y = 6;
        titleFrame.size.height = 34;
        self.titleLabel.frame = titleFrame;
        
        CGRect subtitleFrame = self.subtitleLabel.frame;
        subtitleFrame.origin.y = 40;
        self.subtitleLabel.frame = subtitleFrame;
    }
        
    if(self.selected)
    {
        self.numberLabel.textColor = [UIColor whiteColor];
        self.numberLabel.shadowColor = [UIColor blackColor];
    }
    else if(!episode.watched)
    {
        self.numberLabel.textColor = [UIColor colorWithRed:239/255.0 green:79/255.0 blue:61/255.0 alpha:1];
        self.numberLabel.shadowColor = [UIColor blackColor];
    }
    else
    {
        self.numberLabel.textColor = [UIColor blackColor];
        self.numberLabel.shadowColor = [UIColor clearColor];
    }
    
    if(self.selected)
    {
        self.downloadedIcon.hidden = YES;
    }
    else
    {
        self.downloadedIcon.hidden = (!self.episode.downloadedEnclosures);
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    if(selected)
    {
        self.backgroundColor = [UIColor colorWithRed:61/255.0 green:122/255.0 blue:155/255.0 alpha:1];
        self.titleLabel.textColor = [UIColor whiteColor];
        self.subtitleLabel.textColor = [UIColor whiteColor];
        self.numberLabel.textColor = [UIColor whiteColor];
        
        self.titleLabel.shadowColor = [UIColor blackColor];
        self.subtitleLabel.shadowColor = [UIColor blackColor];
        self.numberLabel.shadowColor = [UIColor blackColor];
        
        self.topLine.hidden = YES;
        self.bottomLine.hidden = YES;
        self.quickPlayButton.hidden = YES;
        self.downloadedIcon.hidden = YES;
    }
    else
    {
        self.backgroundColor = [UIColor clearColor];
        self.titleLabel.textColor = [UIColor blackColor];
        self.subtitleLabel.textColor = [UIColor darkGrayColor];
        
        if(!self.episode.watched)
        {
            self.numberLabel.textColor = [UIColor colorWithRed:239/255.0 green:79/255.0 blue:61/255.0 alpha:1];
            self.numberLabel.shadowColor = [UIColor blackColor];
        }
        else
        {
            self.numberLabel.textColor = [UIColor blackColor];
            self.numberLabel.shadowColor = [UIColor clearColor];
        }
        
        self.titleLabel.shadowColor = [UIColor clearColor];
        self.subtitleLabel.shadowColor = [UIColor clearColor];
        
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
