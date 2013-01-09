//
//  TWEpisodeViewController.m
//  TWiT.tv
//
//  Created by Stuart Moore on 12/29/12.
//  Copyright (c) 2012 Stuart Moore. All rights reserved.
//

#import "TWEpisodeViewController.h"

#import "Episode.h"

@implementation TWEpisodeViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self configureView];
}

#pragma mark - Episode

- (void)setEpisode:(Episode*)episode
{
    if(_episode != episode)
    {
        _episode = episode;
        [self configureView];
    }
}

- (void)configureView
{
    if(self.episode)
    {
        self.title = self.episode.title;
        self.posterView.image = self.episode.poster.image;
        self.dateLabel.text = self.episode.publishedString;
        self.timeLabel.text = self.episode.durationString;
        self.numberLabel.text = @(self.episode.number).stringValue;
        self.descLabel.text = self.episode.desc;
        
        self.guestsLabel.text = self.episode.guests;
    }
}

#pragma mark - Kill

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
