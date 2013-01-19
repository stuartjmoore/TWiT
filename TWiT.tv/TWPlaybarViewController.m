//
//  TWPlaybarViewController.m
//  TWiT.tv
//
//  Created by Stuart Moore on 1/19/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import "TWAppDelegate.h"
#import "TWSplitViewContainer.h"
#import "TWPlayerViewController.h"
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
        
        self.view.layer.cornerRadius = 6;
    }
}

#pragma mark - Actions

- (IBAction)play:(UIButton*)sender
{
    TWAppDelegate *delegate = (TWAppDelegate*)UIApplication.sharedApplication.delegate;
    
    if(sender.selected)
        [delegate pause];
    else
        [delegate play];
    
    sender.selected = !sender.selected;
}
- (IBAction)stop:(UIButton*)sender
{
    TWAppDelegate *delegate = (TWAppDelegate*)UIApplication.sharedApplication.delegate;
    [delegate stop];
    [self.splitViewContainer hidePlaybar];
}

- (IBAction)openPlayer:(id)sender
{
    TWAppDelegate *delegate = (TWAppDelegate*)UIApplication.sharedApplication.delegate;
    
    if(![delegate.nowPlaying isKindOfClass:Enclosure.class])
        return;
    
    TWPlayerViewController *playerController = [self.storyboard instantiateViewControllerWithIdentifier:@"playerController"];
    playerController.splitViewContainer = self.splitViewContainer;
    playerController.enclosure = delegate.nowPlaying;
    
    playerController.view.frame = self.splitViewContainer.view.bounds;
    playerController.view.autoresizingMask = 63;
    [self.splitViewContainer.view addSubview:playerController.view];
    [self.splitViewContainer.view sendSubviewToBack:playerController.view];
    [self.splitViewContainer addChildViewController:playerController];
    
    CGRect masterFrameOriginal = self.splitViewContainer.masterContainer.frame;
    CGRect masterFrameAnimate = masterFrameOriginal;
    masterFrameAnimate.origin.x -= masterFrameAnimate.size.width;
    
    CGRect detailFrameOriginal = self.splitViewContainer.detailContainer.frame;
    CGRect detailFrameAnimate = detailFrameOriginal;
    detailFrameAnimate.origin.x += detailFrameAnimate.size.width;
    
    CGRect modalFrameOriginal = self.splitViewContainer.detailContainer.frame;
    CGRect modalFrameAnimate = modalFrameOriginal;
    if(self.splitViewContainer.modalFlyout.frame.origin.x == 0)
        modalFrameAnimate.origin.x += modalFrameAnimate.size.width;
    
    [UIView animateWithDuration:0.3f animations:^{
        self.splitViewContainer.masterContainer.frame = masterFrameAnimate;
        self.splitViewContainer.detailContainer.frame = detailFrameAnimate;
        
        if(self.splitViewContainer.modalFlyout.frame.origin.x == 0)
            self.splitViewContainer.modalContainer.frame = modalFrameAnimate;
    } completion:^(BOOL fin){
        [self.splitViewContainer.view bringSubviewToFront:playerController.view];
        
        self.splitViewContainer.masterContainer.hidden = YES;
        self.splitViewContainer.detailContainer.hidden = YES;
        
        if(self.splitViewContainer.modalFlyout.frame.origin.x == 0)
            self.splitViewContainer.modalContainer.hidden = YES;
        
        self.splitViewContainer.masterContainer.frame = masterFrameOriginal;
        self.splitViewContainer.detailContainer.frame = detailFrameOriginal;
        
        if(self.splitViewContainer.modalFlyout.frame.origin.x == 0)
            self.splitViewContainer.modalContainer.frame = modalFrameOriginal;
    }];
}

@end
