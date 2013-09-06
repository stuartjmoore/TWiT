//
//  TWPlaybarViewController.m
//  TWiT.tv
//
//  Created by Stuart Moore on 1/19/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import "TWAppDelegate.h"
#import "TWSplitViewContainer.h"
#import "TWNavigationContainer.h"
#import "TWEnclosureViewController.h"
#import "TWStreamViewController.h"
#import "TWPlaybarViewController.h"

#import "Enclosure.h"
#import "Episode.h"
#import "Show.h"

#import "Stream.h"
#import "Channel.h"

@implementation TWPlaybarViewController

- (void)viewDidLoad
{
    self.view.layer.cornerRadius = 4;
}

#pragma mark - Notifications

- (void)playerStateChanged:(NSNotification*)notification
{
    if([notification.name isEqualToString:@"MPMoviePlayerPlaybackStateDidChangeNotification"])
    {
        TWAppDelegate *delegate = (TWAppDelegate*)UIApplication.sharedApplication.delegate;
        self.playButton.selected = (delegate.player.playbackState == MPMoviePlaybackStatePlaying);
    }
}

- (void)updateView
{
    TWAppDelegate *delegate = (TWAppDelegate*)UIApplication.sharedApplication.delegate;
    self.playButton.selected = (delegate.player.playbackState == MPMoviePlaybackStatePlaying);
    
    if([delegate.nowPlaying isKindOfClass:Enclosure.class])
    {
        Enclosure *enclosure = (Enclosure*)delegate.nowPlaying;
        
        self.albumArt.image = enclosure.episode.show.albumArt.image;
        self.titleLabel.text = enclosure.episode.show.title;
        self.subtitleLabel.text = enclosure.episode.title;
    }
    else if([delegate.nowPlaying isKindOfClass:Stream.class])
    {
        Stream *stream = (Stream*)delegate.nowPlaying;
        
        self.titleLabel.text = stream.channel.title;
        
        Event *currentShow = stream.channel.schedule.currentShow;
        if(currentShow)
        {
            NSString *untilString = currentShow.until;
            self.subtitleLabel.text = [NSString stringWithFormat:@"%@ - %@", untilString, currentShow.title];
            self.albumArt.image = currentShow.show.albumArt.image;
            
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateView) object:nil];
            
            if([untilString hasSuffix:@"m"])
                [self performSelector:@selector(updateView) withObject:nil afterDelay:60];
            else if([untilString isEqualToString:@"Pre-show"])
                [self performSelector:@selector(updateView) withObject:nil afterDelay:currentShow.start.timeIntervalSinceNow];
            else if([untilString isEqualToString:@"Live"])
                [self performSelector:@selector(updateView) withObject:nil afterDelay:currentShow.end.timeIntervalSinceNow];
        }
        else
        {
            self.subtitleLabel.text = @"with Leo Laporte";
            self.albumArt.image = [UIImage imageNamed:@"generic.png"];
        }
    }
}

#pragma mark - Actions

- (IBAction)play:(UIButton*)sender
{
    TWAppDelegate *delegate = (TWAppDelegate*)UIApplication.sharedApplication.delegate;
    
    if(delegate.player.playbackState == MPMoviePlaybackStatePlaying)
        [delegate pause];
    else
        [delegate play];
}

- (IBAction)stop:(UIButton*)sender
{
    TWAppDelegate *delegate = (TWAppDelegate*)UIApplication.sharedApplication.delegate;
    [delegate stop];
    
    [self.splitViewContainer hidePlaybar];
    [self.navigationContainer hidePlaybar];
}

#pragma mark - Leave

- (IBAction)openPlayer:(id)sender
{
    TWAppDelegate *delegate = (TWAppDelegate*)UIApplication.sharedApplication.delegate;
    id playerController;
    
    if([delegate.nowPlaying isKindOfClass:Enclosure.class])
    {
        playerController = (TWEnclosureViewController*)[self.storyboard instantiateViewControllerWithIdentifier:@"playerController"];
        [playerController setEnclosure:delegate.nowPlaying];
    }
    else if([delegate.nowPlaying isKindOfClass:Stream.class])
    {
        playerController = (TWStreamViewController*)[self.storyboard instantiateViewControllerWithIdentifier:@"liveController"];
        [playerController setStream:delegate.nowPlaying];
    }
    
    
    if(UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        [self.navigationContainer.masterController pushViewController:playerController animated:YES];
    }
    else if(UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad)
    {
        [playerController setSplitViewContainer:self.splitViewContainer];
        
        [playerController view].frame = self.splitViewContainer.view.bounds;
        [playerController view].autoresizingMask = 63;
        [[self.splitViewContainer view] addSubview:[playerController view]];
        [[self.splitViewContainer view] sendSubviewToBack:[playerController view]];
        [self.splitViewContainer addChildViewController:playerController];
        [self setNeedsStatusBarAppearanceUpdate];
        
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
            [self.splitViewContainer.view bringSubviewToFront:[playerController view]];
            
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
}

@end
