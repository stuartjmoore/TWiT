//
//  TWPlaybarViewController.m
//  TWiT.tv
//
//  Created by Stuart Moore on 1/19/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import "TWAppDelegate.h"
#import "TWPlaybarViewController.h"

#import "Enclosure.h"
#import "Episode.h"
#import "Show.h"

@implementation TWPlaybarViewController

- (void)updateView
{
    TWAppDelegate *delegate = (TWAppDelegate*)UIApplication.sharedApplication.delegate;
    
    if([delegate.nowPlaying isKindOfClass:Enclosure.class])
    {
        Enclosure *enclosure = (Enclosure*)delegate.nowPlaying;
        
        self.albumArt.image = enclosure.episode.show.albumArt.image;
        self.titleLabel.text = enclosure.episode.show.title;
        self.subtitleLabel.text = enclosure.episode.title;
    }
}

#pragma mark - Actions

- (IBAction)play:(id)sender
{
    
}

- (IBAction)openPlayer:(id)sender
{
    
}

@end
