//
//  TWEpisodeViewController.m
//  TWiT.tv
//
//  Created by Stuart Moore on 12/29/12.
//  Copyright (c) 2012 Stuart Moore. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "TWEpisodeViewController.h"

#import "Episode.h"

@implementation TWEpisodeViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    CAGradientLayer *liveGradient = [CAGradientLayer layer];
    liveGradient.anchorPoint = CGPointMake(0, 0);
    liveGradient.position = CGPointMake(0, 0);
    liveGradient.startPoint = CGPointMake(0, 1);
    liveGradient.endPoint = CGPointMake(0, 0);
    liveGradient.bounds = self.gradientView.bounds;
    liveGradient.colors = [NSArray arrayWithObjects:
                           (id)[UIColor colorWithWhite:0 alpha:1].CGColor,
                           (id)[UIColor colorWithWhite:0 alpha:0.6f].CGColor,
                           (id)[UIColor colorWithWhite:0 alpha:0].CGColor, nil];
    [self.gradientView.layer addSublayer:liveGradient];
    
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

#pragma mark - Settings

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if(UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad)
        return YES;
    else
        return (interfaceOrientation == UIInterfaceOrientationMaskPortrait);
}

- (NSUInteger)supportedInterfaceOrientations
{
    if(UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad)
        return UIInterfaceOrientationMaskAll;
    else
        return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - Kill

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
